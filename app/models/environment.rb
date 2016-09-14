class Environment < ActiveRecord::Base
  belongs_to :project, required: true, validate: true

  has_many :deployments

  before_validation :nullify_external_url
  before_save :set_environment_type

  validates :name,
            presence: true,
            uniqueness: { scope: :project_id },
            length: { within: 0..255 },
            format: { with: Gitlab::Regex.environment_name_regex,
                      message: Gitlab::Regex.environment_name_regex_message }

  validates :external_url,
            uniqueness: { scope: :project_id },
            length: { maximum: 255 },
            allow_nil: true,
            addressable_url: true

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

  def deployment_id_for(commit)
    project.repository.ref_name_for_sha(ref_path, commit.sha)
  end

  def ref_path
    "refs/environments/#{Shellwords.shellescape(name)}/"
  end
end
