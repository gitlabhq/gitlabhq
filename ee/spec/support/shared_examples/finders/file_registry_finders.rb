shared_examples_for 'a file registry finder' do
  it 'responds to file registry finder methods' do
    file_registry_finder_methods = %i{
      syncable
      count_syncable
      count_synced
      count_failed
      count_synced_missing_on_primary
      count_registry
      find_unsynced
      find_migrated_local
      find_retryable_failed_registries
      find_retryable_synced_missing_on_primary_registries
    }

    file_registry_finder_methods.each do |method|
      expect(subject).to respond_to(method)
    end
  end

  # Disable transactions via :delete method because a foreign table
  # can't see changes inside a transaction of a different connection.
  context 'FDW', :delete do
    before do
      skip('FDW is not configured') if Gitlab::Database.postgresql? && !Gitlab::Geo::Fdw.enabled?
    end

    include_examples 'counts all the things'

    include_examples 'finds all the things' do
      let(:method_prefix) { 'fdw' }
    end
  end

  context 'Legacy' do
    before do
      allow(Gitlab::Geo::Fdw).to receive(:enabled?).and_return(false)
    end

    include_examples 'counts all the things'

    include_examples 'finds all the things' do
      let(:method_prefix) { 'legacy' }
    end
  end
end
