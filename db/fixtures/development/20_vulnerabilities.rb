require './spec/support/sidekiq'

class Gitlab::Seeder::Vulnerabilities
  attr_reader :project

  def initialize(project)
    @project = project
  end

  def seed!
    return unless pipeline

    10.times do |rank|
      occurrence = create_occurrence(rank)
      create_occurrence_identifier(occurrence, rank, primary: true)
      create_occurrence_identifier(occurrence, rank)

      if author
        case rank % 3
        when 0
          create_feedback(occurrence, 'dismissal')
        when 1
          create_feedback(occurrence, 'issue')
        else
          # no feedback
        end
      end
    end
  end

  private

  def create_occurrence(rank)
    project.vulnerabilities.create!(
      uuid: random_uuid,
      name: 'Cipher with no integrity',
      pipeline: pipeline,
      ref: project.default_branch,
      report_type: :sast,
      severity: random_level,
      confidence: random_level,
      project_fingerprint: random_fingerprint,
      primary_identifier_fingerprint: random_fingerprint,
      location_fingerprint: random_fingerprint,
      raw_metadata: metadata(rank).to_json,
      metadata_version: 'sast:1.0',
      scanner: scanner)
  end

  def create_occurrence_identifier(occurrence, key, primary: false)
    type = primary ? 'primary' : 'secondary'
    fingerprint = if primary
                    occurrence.primary_identifier_fingerprint
                  else
                    Digest::SHA1.hexdigest("sid_fingerprint-#{project.id}-#{key}")
                  end

    project.vulnerability_identifiers.create!(
      external_type: "#{type.upcase}_SECURITY_ID",
      external_id: "#{type.upcase}_SECURITY_#{key}",
      fingerprint: fingerprint,
      name: "#{type.capitalize} #{key}",
      url: "https://security.example.com/#{type.downcase}/#{key}"
    )
  end

  def create_feedback(occurrence, type)
    issue = create_issue("Dismiss #{occurrence.name}") if type == 'issue'
    project.vulnerability_feedback.create!(
      feedback_type: type,
      category: 'sast',
      author: author,
      issue: issue,
      pipeline: pipeline,
      project_fingerprint: occurrence.project_fingerprint,
      vulnerability_data: { category: 'sast' })
  end

  def scanner
    @scanner ||= project.vulnerability_scanners.create!(
      project: project,
      external_id: 'security-scanner',
      name: 'Security Scanner')
  end

  def create_issue(title)
    project.issues.create!(author: author, title: title)
  end

  def random_level
    ::Vulnerabilities::Occurrence::LEVELS.keys.sample
  end

  def metadata(line)
    {
      description: "The cipher does not provide data integrity update 1",
      solution: "GCM mode introduces an HMAC into the resulting encrypted data, providing integrity of the result.",
      location: {
        file: "maven/src/main/java//App.java",
        start_line: line,
        end_line: line,
        class: "com.gitlab..App",
        method: "insecureCypher"
      },
      links: [
        {
          name: "Cipher does not check for integrity first?",
          url: "https://crypto.stackexchange.com/questions/31428/pbewithmd5anddes-cipher-does-not-check-for-integrity-first"
        }
      ]
    }
  end

  def random_uuid
    SecureRandom.hex(18)
  end

  def random_fingerprint
    SecureRandom.hex(20)
  end

  def pipeline
    @pipeline ||= project.pipelines.where(ref: project.default_branch).last
  end

  def author
    @author ||= project.users.first
  end
end

Gitlab::Seeder.quiet do
  Project.joins(:pipelines).uniq.all.sample(5).each do |project|
    seeder = Gitlab::Seeder::Vulnerabilities.new(project)
    seeder.seed!
  end
end
