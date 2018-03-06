# An InternalId is a strictly monotone sequence of integers
# for a given project and usage (e.g. issues).
#
# For possible usages, see InternalId#usage enum.
class InternalId < ActiveRecord::Base
  belongs_to :project

  enum usage: { issues: 0 }

  validates :usage, presence: true
  validates :project_id, presence: true

  # Increments #last_value and saves the record
  #
  # The operation locks the record and gathers
  # a `ROW SHARE` lock (in PostgreSQL). As such,
  # the increment is atomic and safe to be called
  # concurrently.
  def increment_and_save!
    lock!
    self.last_value = (last_value || 0) + 1
    save!
    last_value
  end

  before_create :calculate_last_value!

  # Calculate #last_value by counting the number of
  # existing records for this usage.
  def calculate_last_value!
    return if last_value

    parent = project # ??|| group
    self.last_value = parent.send(usage.to_sym).maximum(:iid) || 0 # rubocop:disable GitlabSecurity/PublicSend
  end

  class << self
    # Generate next internal id for a given project and usage.
    #
    # For currently supported usages, see #usage enum.
    #
    # The method implements a locking scheme that has the following properties:
    # 1) Generated sequence of internal ids is unique per (project, usage)
    # 2) The method is thread-safe and may be used in concurrent threads/processes.
    # 3) The generated sequence is gapless.
    # 4) In the absence of a record in the internal_ids table, one will be created
    #    and last_value will be calculated on the fly.
    def generate_next(project, usage)
      raise 'project not set - this is required' unless project

      project.transaction do
        # Create a record in internal_ids if one does not yet exist
        id = (lookup(project, usage) || create_record(project, usage))

        # This will lock the InternalId record with ROW SHARE
        # and increment #last_value
        id.increment_and_save!
      end
    end

    private

    # Retrieve InternalId record for (project, usage) combination, if it exists
    def lookup(project, usage)
      project.internal_ids.find_by(usage: usages[usage.to_s])
    end

    # Create InternalId record for (project, usage) combination, if it doesn't exist
    #
    # We blindly insert without any synchronization. If another process
    # was faster in doing this, we'll realize once we hit the unique key constraint
    # violation. We can safely roll-back the nested transaction and perform
    # a lookup instead to retrieve the record.
    def create_record(project, usage)
      begin
        project.transaction(requires_new: true) do
          create!(project: project, usage: usages[usage.to_s])
        end
      rescue ActiveRecord::RecordNotUnique
        lookup(project, usage)
      end
    end
  end
end
