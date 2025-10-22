# Code Embeddings Indexing Pipeline

This guide provides step-by-step instructions for setting up and using the Code Embeddings Indexing Pipeline for ActiveContext in your local GitLab development environment.

**Important**: This process currently requires several local development hacks to work around production constraints. These workarounds are documented at each relevant step below. Future improvements should aim to eliminate these workarounds and simplify the setup process.

## Prerequisites

- GitLab Development Kit (GDK) running in [SaaS mode](https://docs.gitlab.com/development/ee_features/#simulate-a-saas-instance)
- Install [AI Gateway](https://docs.gitlab.com/development/ai_features/#install-ai-gateway)
- Access to GitLab rails console

## Infrastructure Setup

### Elasticsearch and Kibana

1. Install and configure Elasticsearch following the [GDK Elasticsearch guide](https://gitlab.com/gitlab-org/gitlab-development-kit/-/blob/main/doc/howto/elasticsearch.md).

2. Install Kibana:

   ```bash
   brew tap elastic/tap
   brew install elastic/tap/kibana-full
   ```

3. Start Kibana:

   ```bash
   # As a background service
   brew services start elastic/tap/kibana-full

   # Or in foreground
   /opt/homebrew/opt/kibana-full/bin/kibana
   ```

4. Access Kibana at [http://localhost:5601/app/dev_tools#/console](http://localhost:5601/app/dev_tools#/console).

### Optional: Enable Elasticsearch slowlog monitoring

To monitor ActiveContext operations, enable debug logging for both indices:

```bash
# For gitlab_active_context_code_0
curl -H 'Content-Type: application/json' -XPUT "http://localhost:9200/gitlab_active_context_code_0/_settings" -d '{
"index.indexing.slowlog.threshold.index.debug" : "0s",
"index.search.slowlog.threshold.fetch.debug" : "0s",
"index.search.slowlog.threshold.query.debug" : "0s"
}'

# For gitlab_active_context_code_1
curl -H 'Content-Type: application/json' -XPUT "http://localhost:9200/gitlab_active_context_code_1/_settings" -d '{
"index.indexing.slowlog.threshold.index.debug" : "0s",
"index.search.slowlog.threshold.fetch.debug" : "0s",
"index.search.slowlog.threshold.query.debug" : "0s"
}'
```

## ActiveContext Configuration

### Enable Required Feature Flags

In GitLab rails console:

```ruby
Feature.enable(:active_context_code_incremental_index_project)
Feature.enable(:active_context_code_index_project)
```

### Create and Activate Connection

**Note**: If you already have an Elasticsearch connection for advanced search, you can reuse it by setting `use_advanced_search_config` to `true`:

```ruby
connection = Ai::ActiveContext::Connection.create!(
  name: "elastic",
  adapter_class: "ActiveContext::Databases::Elasticsearch::Adapter",
  options: {"use_advanced_search_config" => true }
)
```

Alternatively, create a new connection with explicit URL:

```ruby
connection = Ai::ActiveContext::Connection.create!(
  name: "elastic",
  adapter_class: "ActiveContext::Databases::Elasticsearch::Adapter",
  options: {"url" => ["http://localhost:9200"]}
)
```

Activate the connection:

```ruby
connection.activate!
```

### Run Migration Worker

Execute the migration worker. This should be run until all pending migrations are complete (verify using the SQL query in the Verification Steps section):

```ruby
Ai::ActiveContext::MigrationWorker.new.perform
```

The worker runs on a cron schedule. You can run manually to ensure all migrations are complete.

**Tip**: Monitor the `log/active_context.log` file to track migration progress:

```bash
tail -f log/active_context.log | jq
```

## Verification Steps

### Verify Elasticsearch Indices

In Kibana Dev Tools console ([http://localhost:5601/app/dev_tools#/console](http://localhost:5601/app/dev_tools#/console)):

```
GET gitlab_active_context_code
```

This should return index information if the migration was successful.

### Verify Collection Record

In GitLab rails console:

```ruby
ActiveContext.adapter.connection.collections
```

Expected output should include a collection record with:
- `name: "gitlab_active_context_code"`
- `number_of_partitions: 1`
- Other metadata fields

### Verify Migration Status

If migrations fail, check the database:

```bash
gdk psql
```

```sql
SELECT * FROM ai_active_context_migrations;
```

Check the `error_message` column for any issues. To reset migrations:

```sql
DELETE FROM ai_active_context_migrations;
```

Then re-run the migration worker.

## Indexing Pipeline Workflow

### Setup Eligible Namespace

Create or ensure a namespace meets these eligibility criteria:
- Active, non-trial Duo Core, Pro, or Enterprise license
- Unexpired paid hosted GitLab subscription
- Namespace has `duo_features_enabled` AND `experiment_features_enabled`

#### Use "gitlab-duo/test" project

A simpler alternative would be to use `gitlab-duo/test` project:

```ruby
project = Project.find_by_full_path("gitlab-duo/test")
namespace = project.namespace
```

Enable indexing for your namespace:

```ruby
Feature.enable(:active_context_saas_initial_indexing_namespace, namespace)
```

#### Check if the namespace is eligible

```ruby
project = Project.find_by_full_path("gitlab-duo/test")
namespace = project.namespace

GitlabSubscriptions::AddOnPurchase.active.non_trial.for_duo_core_pro_or_enterprise.by_namespace(namespace.id)
# Should return a GitlabSubscriptions::AddOnPurchase record

GitlabSubscription.with_a_paid_hosted_plan.not_expired.namespace_id_in(namespace.id)
# Should return a GitlabSubscription record

namespace.duo_features_enabled
# Should be true

namespace.experiment_features_enabled
# Should be true
```

### Run Initial Indexing Workflow

**Required Local Development Patches**: Apply these patches before starting the workflow:

**1. Run all workers synchronously instead of async to avoid Redis/Sidekiq dependency:**

```diff
# lib/gitlab/event_store/subscription.rb
@@ -19,11 +19,7 @@ def initialize(worker, condition, delay, group_size)
       def consume_event(event)
         return unless condition_met?(event)

-        if delay
-          worker.perform_in(delay, event.class.name, event.data.deep_stringify_keys.to_h)
-        else
-          worker.perform_async(event.class.name, event.data.deep_stringify_keys.to_h)
-        end
+        worker.new.perform(event.class.name, event.data.deep_stringify_keys.to_h)

         # We rescue and track any exceptions here because we don't want to
         # impact other subscribers if one is faulty.
```

**2. Make repository workers run synchronously:**

```diff
# ee/app/services/ai/active_context/code/repository_index_service.rb
@@ -11,7 +11,7 @@ def self.enqueue_pending_jobs
             .pending.with_active_connection
             .limit(PROCESS_PENDING_LIMIT)
             .each do |repository|
-              RepositoryIndexWorker.perform_async(repository.id)
+              RepositoryIndexWorker.new.perform(repository.id)
             end
         end
       end
```

**3. Disable migration caching to see real-time changes:**

```diff
# ee/app/models/ai/active_context/migration.rb
@@ -35,9 +35,7 @@ def self.current
       end

       def self.complete?(identifier)
-        Rails.cache.fetch [:ai_active_context_migration_completed, identifier], expires_in: CACHE_TIMEOUT do
-          check_complete_uncached(identifier)
-        end
+        check_complete_uncached(identifier)
       end

       private_class_method def self.check_complete_uncached(identifier)
```

**4. Enable SaaS features locally by patching the SaaS check:**

```diff
# ee/lib/ee/gitlab/saas.rb
@@ -53,6 +53,7 @@ module Saas

       class_methods do
         def feature_available?(feature)
+          return true
           raise MissingFeatureError, 'Feature does not exist' unless FEATURES.include?(feature)

           enabled?
```

Execute these scheduling tasks in sequence:

#### 1. Create EnabledNamespace Records


Now run the initial indexing:

```ruby
Ai::ActiveContext::Code::SchedulingWorker.new.perform("saas_initial_indexing")
# Creates Ai::ActiveContext::Code::EnabledNamespace records
```

#### 2. Process Enabled Namespaces

```ruby
Ai::ActiveContext::Code::SchedulingWorker.new.perform("process_pending_enabled_namespace")

# Sets Ai::ActiveContext::Connection.active.enabled_namespaces to ready
# Creates repository records: Ai::ActiveContext::Connection.active.enabled_namespaces.first.repositories
```

#### 3. Index Repositories

```ruby
# Note: Repository state might need to be set to pending if it's already ready
Ai::ActiveContext::Code::Repository.last.update!(state: "pending", last_commit: nil, metadata: {})

Ai::ActiveContext::Code::SchedulingWorker.new.perform("index_repository")

# Creates records on Elasticsearch
ActiveContext.adapter.client.client.search(index: "gitlab_active_context_code").dig("hits", "total", "value")

# Sets repository state to embedding_indexing_in_progress
Ai::ActiveContext::Connection.active.enabled_namespaces.first.repositories

# Enqueues embedding references
Ai::ActiveContext::Queues::Code.queue_size
# or
ActiveContext::Queues.all_queued_items
```

#### 4. Generate and Store Embeddings

Execute single queue:

```ruby
::Ai::ActiveContext::BulkProcessWorker.new.perform("Ai::ActiveContext::Queues::Code", 0)
```

Execute all queues:

```ruby
ActiveContext.execute_all_queues!
# Continue running until Ai::ActiveContext::Queues::Code.queue_size returns 0

# NOTE: If the queue count doesn't decrease, see "Queue count remains unchanged" in Troubleshooting
```

#### 5. Mark Repository as Ready

```ruby
Ai::ActiveContext::Code::SchedulingWorker.new.perform("mark_repository_as_ready")

# Changes repository state to ready
Ai::ActiveContext::Connection.active.enabled_namespaces.first.repositories
```

### Verify Indexing Results

Check if documents were indexed:

```bash
curl -X GET "http://localhost:9200/gitlab_active_context_code/_search?pretty" -H 'Content-Type: application/json' -d '
{
  "query": {
    "match_all": {}
  },
  "size": 100
}'
```

View repository states:

```ruby
Ai::ActiveContext::Connection.active.enabled_namespaces.first.repositories
```

Check queue status:

```ruby
Ai::ActiveContext::Queues::Code.queue_size
```

or

```ruby
ActiveContext::Queues.all_queued_items
```

## Alternative: Manual Indexing with gitlab-elasticsearch-indexer

For direct indexing without the Rails workflow:

### Get Project Information

```ruby
p = Project.find_by_full_path('gitlab-org/gitlab-test')
p.repository.relative_path
# => "@hashed/6b/86/6b86b273ff34fce19d6b804eff5a3f5747ada4eaa22f1d49c01e52ddb7875b4b.git"
```

### Run Elasticsearch Indexer

Clone and build the indexer:

```bash
git clone https://gitlab.com/gitlab-org/gitlab-elasticsearch-indexer
cd gitlab-elasticsearch-indexer
make
```

Run the indexer (update paths and IDs as needed):

```bash
make && \
GITLAB_INDEXER_MODE=chunk \
GITLAB_INDEXER_DEBUG_LOGGING=1 \
./bin/gitlab-elasticsearch-indexer \
-adapter "elasticsearch" \
-connection '{"url": ["http://localhost:9200"]}' \
-options '{
  "timeout": "30m",
  "chunk_size": 1000,
  "gitaly_batch_size": 1000,
  "from_sha": "",
  "to_sha": "",
  "project_id": 2,
  "partition_name": "gitlab_active_context_code",
  "partition_number": 0,
  "gitaly_config": {
    "address": "unix:/Users/arturo/projects/gdk/praefect.socket",
    "storage": "default",
    "relative_path": "@hashed/6b/86/6b86b273ff34fce19d6b804eff5a3f5747ada4eaa22f1d49c01e52ddb7875b4b.git",
    "project_path": "gitlab-org/gitlab-test"
  }
}'
```

**Note**: Update the `address` path to match your actual GDK setup. You can find your praefect socket path in your GDK configuration.


## Performing Searches

Once indexing is complete, you can search the code embeddings:

```ruby
results = Ai::ActiveContext::Collections::Code.search(
  query: ActiveContext::Query.knn(content: "gitaly client", k: 5),
  user: User.first
)

results.map { |r| r["content"] }

# NOTE: If you see "Forbidden by auth provider", see Troubleshooting section
```

## Index State Tracking: Incremental Updates (Optional)

For tracking incremental changes and updates to the indexed code, the system maintains state information that allows for efficient re-indexing of only changed content.

## Cleanup and Reset

To start fresh:

```ruby
# Delete the Elasticsearch index
ActiveContext.adapter.client.client.indices.delete(index: "gitlab_active_context_code_0")

# Delete the active connection record => this deletes connected Collection, Migration and EnabledNamespace records
Ai::ActiveContext::Connection.active.destroy

# Clean up related records
Ai::ActiveContext::Code::EnabledNamespace.destroy_all
Ai::ActiveContext::Code::Repository.destroy_all

# Clear Redis queues
Ai::ActiveContext::Queues::Code.clear_tracking!

# Verify cleanup
Ai::ActiveContext::Queues::Code.queued_items  # Should return empty hash

# Alternative verification using curl
curl -X GET "http://localhost:9200/gitlab_active_context_code_0/_search?pretty" -H 'Content-Type: application/json' -d '
{
  "query": {
    "match_all": {}
  },
  "size": 100
}'
# Should return null/empty results
```

## Troubleshooting

### Common Issues

1. **Migration failures**: Check `ai_active_context_migrations` table for error messages
2. **Connection issues**: Ensure Elasticsearch is running and accessible on localhost:9200
3. **Permission errors**: Verify namespace eligibility criteria are met
4. **No collection_class set**: This is expected in the current setup - the collection record may show `collection_class: nil`

#### Queue count remains unchanged after execution

If the queue count doesn't decrease after running `ActiveContext.execute_all_queues!`, verify that your environment can send embedding requests to AI Gateway (AIGW).

Test the connection with:

```ruby
Gitlab::Llm::VertexAi::Embeddings::Text.new(
  "some text",
  user: User.first,
  tracking_context: { action: 'embedding' },
  unit_primitive: 'generate_embeddings_codebase',
  model: 'text-embedding-005'
).execute
```

If this request returns a "Forbidden by auth provider" error, please refer to the section below.

For other failures, please double check the [AIGW installation documentation](https://docs.gitlab.com/development/ai_features/).
If you are still stuck, you can contact `#subteam-codebase-as-chat-context` or `#f_ai-gateway` for assistance.

#### "Forbidden by auth provider" error during search

This error occurs when AI Gateway (AIGW) lacks the necessary permissions to access Google Vertex AI.

**Resolution steps:**
1. Verify your local Rails instance is configured to connect to your local AIGW instance
2. Ensure your local AIGW has valid credentials and permissions to access Google Vertex AI
3. Check AIGW logs for authentication errors

Refer to the [AIGW Authentication and Authorization doc](https://gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist/-/blob/main/docs/auth.md) for further details on configuring AIGW permissions.

If you are still stuck, you can contact `#subteam-codebase-as-chat-context` or `#f_ai-gateway` for assistance.

