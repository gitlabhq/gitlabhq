class InternalId < ActiveRecord::Base
  # Increments #last_value and saves the record
  #
  # The operation locks the record and gathers a `ROW SHARE` lock (in PostgreSQL).
  # As such, the increment is atomic and safe to be called concurrently.
  def increment_and_save!
    lock!
    self.last_value = (last_value || 0) + 1
    save!
    last_value
  end

  class << self
    # Generate next internal id for given subject.
    #
    # subject: The instance we generate the internal id for
    # scope: The instance that defines the scope for internal ids (symbol)
    # through: The attribute of the scope that holds the foreign key to InternalId (symbol)
    # init: A lambda to initialize InternalId with correct last_value. Gets subject passed in.
    def generate!(subject, scope:, through:, init: nil)
      raise "Unknown scope '#{scope}' for #{subject}" unless subject.respond_to?(scope)

      scope = subject.public_send(scope) # rubocop:disable GitlabSecurity/PublicSend

      raise "Unknown through '#{through}' for '#{scope}'" unless scope.respond_to?(through)

      scope.transaction do
        # Reload scope so we can check if the foreign key to InternalId is present already
        scope.reload

        # Create a record in internal_ids if one does not yet exist
        id = get(scope, through) || create_record(subject, scope, through, init).tap do |id|
          scope.public_send("#{through}=".to_sym, id)
          scope.save!
        end

        # This will lock the InternalId record with ROW SHARE
        # and increment #last_value
        id.increment_and_save!
      end
    end

    private

    # Retrieves the InternalId record from the given scope if present
    def get(scope, through)
      scope.public_send(through) # rubocop:disable GitlabSecurity/PublicSend
    end

    # Create InternalId record, if it doesn't exist
    #
    # This gathers a ROW SHARE lock on the scope instance. This is necessary
    # to synchronize concurrent operations for the same scope in the absence
    # of a InternalId record.
    #
    # Note the scope instance is updated if a InternalId record was created.
    def create_record(subject, scope, through, init)
      # Reload and lock scope object with ROW SHARE (FOR UPDATE)
      # This is important to avoid two concurrent processes to
      # create a new InternalId record each and update the `through`
      # column (one record will be lost in the process).
      scope.lock!
      get(scope, through) || new(last_value: init.call(subject) || 0)
    end
  end
end
