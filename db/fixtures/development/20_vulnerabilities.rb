require './spec/support/sidekiq'

class Gitlab::Seeder::Vulnerabilities
  attr_reader :project

  def initialize(project)
    @project = project
  end

  def seed!
    return unless pipeline

    10.times do |rank|
      primary_identifier = create_identifier(rank)
      occurrence = create_occurrence(rank, primary_identifier)
      # Create occurrence_pipeline join model
      occurrence.pipelines << pipeline
      # Create occurrence_identifier join models
      occurrence.identifiers << primary_identifier
      occurrence.identifiers << create_identifier(rank) if rank % 3 == 0

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

  def create_occurrence(rank, primary_identifier)
    project.vulnerabilities.create!(
      uuid: random_uuid,
      name: 'Cipher with no integrity',
      report_type: :sast,
      severity: random_severity_level,
      confidence: random_confidence_level,
      project_fingerprint: random_fingerprint,
      location_fingerprint: random_fingerprint,
      primary_identifier: primary_identifier,
      raw_metadata: metadata(rank).to_json,
      metadata_version: 'sast:1.0',
      scanner: scanner)
  end

  def create_identifier(rank)
    project.vulnerability_identifiers.create!(
      external_type: "SECURITY_ID",
      external_id: "SECURITY_#{rank}",
      fingerprint: random_fingerprint,
      name: "SECURITY_IDENTIFIER #{rank}",
      url: "https://security.example.com/#{rank}"
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

  def random_confidence_level
    ::Vulnerabilities::Occurrence::CONFIDENCE_LEVELS.keys.sample
  end

  def random_severity_level
    ::Vulnerabilities::Occurrence::SEVERITY_LEVELS.keys.sample
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
    @pipeline ||= project.ci_pipelines.where(ref: project.default_branch).last
  end

  def author
    @author ||= project.users.first
  end
end

Gitlab::Seeder.quiet do
  Project.joins(:ci_pipelines).distinct.all.sample(5).each do |project|
    seeder = Gitlab::Seeder::Vulnerabilities.new(project)
    seeder.seed!
  end
end
