export default class GeoNodesStore {
  constructor(primaryVersion, primaryRevision) {
    this.state = {};
    this.state.nodes = [];
    this.state.nodeDetails = {};
    this.state.primaryVersion = primaryVersion;
    this.state.primaryRevision = primaryRevision;
  }

  setNodes(nodes) {
    this.state.nodes = nodes;
  }

  getNodes() {
    return this.state.nodes;
  }

  setNodeDetails(nodeId, nodeDetails) {
    this.state.nodeDetails[nodeId] = GeoNodesStore.formatNodeDetails(nodeDetails);
  }

  getPrimaryNodeVersion() {
    return {
      version: this.state.primaryVersion,
      revision: this.state.primaryRevision,
    };
  }

  getNodeDetails(nodeId) {
    return this.state.nodeDetails[nodeId];
  }

  static formatNodeDetails(rawNodeDetails) {
    return {
      id: rawNodeDetails.geo_node_id,
      health: rawNodeDetails.health,
      healthy: rawNodeDetails.healthy,
      healthStatus: rawNodeDetails.health_status,
      version: rawNodeDetails.version,
      revision: rawNodeDetails.revision,
      primaryVersion: rawNodeDetails.primaryVersion,
      primaryRevision: rawNodeDetails.primaryRevision,
      replicationSlotWAL: rawNodeDetails.replication_slots_max_retained_wal_bytes,
      missingOAuthApplication: rawNodeDetails.missing_oauth_application,
      storageShardsMatch: rawNodeDetails.storage_shards_match,
      replicationSlots: {
        totalCount: rawNodeDetails.replication_slots_count,
        successCount: rawNodeDetails.replication_slots_used_count,
        failureCount: 0,
      },
      repositories: {
        totalCount: rawNodeDetails.repositories_count,
        successCount: rawNodeDetails.repositories_synced_count,
        failureCount: rawNodeDetails.repositories_failed_count,
      },
      wikis: {
        totalCount: rawNodeDetails.wikis_count,
        successCount: rawNodeDetails.wikis_synced_count,
        failureCount: rawNodeDetails.wikis_failed_count,
      },
      lfs: {
        totalCount: rawNodeDetails.lfs_objects_count,
        successCount: rawNodeDetails.lfs_objects_failed_count,
        failureCount: rawNodeDetails.lfs_objects_synced_count,
      },
      attachments: {
        totalCount: rawNodeDetails.attachments_count,
        successCount: rawNodeDetails.attachments_synced_count,
        failureCount: rawNodeDetails.attachments_failed_count,
      },
      lastEvent: {
        id: rawNodeDetails.last_event_id,
        timeStamp: rawNodeDetails.last_event_timestamp,
      },
      cursorLastEvent: {
        id: rawNodeDetails.cursor_last_event_id,
        timeStamp: rawNodeDetails.cursor_last_event_timestamp,
      },
      namespaces: rawNodeDetails.namespaces,
      dbReplicationLag: rawNodeDetails.db_replication_lag_seconds,
    };
  }
}
