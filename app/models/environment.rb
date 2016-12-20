class Environment < ActiveRecord::Base
  # Used to generate random suffixes for the slug
  NUMBERS = '0'..'9'
  SUFFIX_CHARS = ('a'..'z').to_a + NUMBERS.to_a

  belongs_to :project, required: true, validate: true

  has_many :deployments

  before_validation :nullify_external_url
  before_validation :generate_slug, if: ->(env) { env.slug.blank? }

  before_save :set_environment_type

  validates :name,
            presence: true,
            uniqueness: { scope: :project_id },
            length: { maximum: 255 },
            format: { with: Gitlab::Regex.environment_name_regex,
                      message: Gitlab::Regex.environment_name_regex_message }

  validates :slug,
            presence: true,
            uniqueness: { scope: :project_id },
            length: { maximum: 24 },
            format: { with: Gitlab::Regex.environment_slug_regex,
                      message: Gitlab::Regex.environment_slug_regex_message }

  validates :external_url,
            uniqueness: { scope: :project_id },
            length: { maximum: 255 },
            allow_nil: true,
            addressable_url: true

  delegate :stop_action, :manual_actions, to: :last_deployment, allow_nil: true

  scope :available, -> { with_state(:available) }
  scope :stopped, -> { with_state(:stopped) }

  state_machine :state, initial: :available do
    event :start do
      transition stopped: :available
    end

    event :stop do
      transition available: :stopped
    end

    state :available
    state :stopped
  end

  def predefined_variables
    [
      { key: 'CI_ENVIRONMENT_NAME', value: name, public: true },
      { key: 'CI_ENVIRONMENT_SLUG', value: slug, public: true },
    ]
  end

  def recently_updated_on_branch?(ref)
    ref.to_s == last_deployment.try(:ref)
  end

  def last_deployment
    deployments.last
  end

  def nullify_external_url
    self.external_url = nil if self.external_url.blank?
  end

  def set_environment_type
    names = name.split('/')

    self.environment_type =
      if names.many?
        names.first
      else
        nil
      end
  end

  def includes_commit?(commit)
    return false unless last_deployment

    last_deployment.includes_commit?(commit)
  end

  def update_merge_request_metrics?
    self.name == "production"
  end

  def first_deployment_for(commit)
    ref = project.repository.ref_name_for_sha(ref_path, commit.sha)

    return nil unless ref

    deployment_iid = ref.split('/').last
    deployments.find_by(iid: deployment_iid)
  end

  def ref_path
    "refs/environments/#{Shellwords.shellescape(name)}"
  end

  def formatted_external_url
    return nil unless external_url

    external_url.gsub(/\A.*?:\/\//, '')
  end

  def stoppable?
    available? && stop_action.present?
  end

  def stop!(current_user)
    return unless stoppable?

    stop
    stop_action.play(current_user)
  end

  def actions_for(environment)
    return [] unless manual_actions

    manual_actions.select do |action|
      action.expanded_environment_name == environment
    end
  end

  def has_terminals?
    project.deployment_service.present? && available? && last_deployment.present?
  end

  def terminals
    project.deployment_service.terminals(self) if has_terminals?
  end

  # An environment name is not necessarily suitable for use in URLs, DNS
  # or other third-party contexts, so provide a slugified version. A slug has
  # the following properties:
  #   * contains only lowercase letters (a-z), numbers (0-9), and '-'
  #   * begins with a letter
  #   * has a maximum length of 24 bytes (OpenShift limitation)
  #   * cannot end with `-`
  def generate_slug
    # Lowercase letters and numbers only
    slugified = name.to_s.downcase.gsub(/[^a-z0-9]/, '-')

    # Must start with a letter
    slugified = "env-" + slugified if NUMBERS.cover?(slugified[0])

    # Maximum length: 24 characters (OpenShift limitation)
    slugified = slugified[0..23]

    # Cannot end with a "-" character (Kubernetes label limitation)
    slugified = slugified[0..-2] if slugified[-1] == "-"

    # Add a random suffix, shortening the current string if necessary, if it
    # has been slugified. This ensures uniqueness.
    slugified = slugified[0..16] + "-" + random_suffix if slugified != name

    self.slug = slugified
  end

  private

  # Slugifying a name may remove the uniqueness guarantee afforded by it being
  # based on name (which must be unique). To compensate, we add a random
  # 6-byte suffix in those circumstances. This is not *guaranteed* uniqueness,
  # but the chance of collisions is vanishingly small
  def random_suffix
    (0..5).map { SUFFIX_CHARS.sample }.join
  end
end
