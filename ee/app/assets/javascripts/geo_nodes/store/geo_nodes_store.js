export default class GeoNodesStore {
  constructor(primaryVersion, primaryRevision) {
    this.state = {};
    this.state.nodes = [];
    this.state.nodeDetails = {};
    this.state.primaryVersion = primaryVersion;
    this.state.primaryRevision = primaryRevision;
  }

  setNodes(nodes) {
    this.state.nodes = nodes.map(
      node => GeoNodesStore.formatNode(node),
    );
  }

  getNodes() {
    return this.state.nodes;
  }

  setNodeDetails(nodeId, nodeDetails) {
    this.state.nodeDetails[nodeId] = GeoNodesStore.formatNodeDetails(nodeDetails);
  }

  removeNode(node) {
    const indexOfRemovedNode = this.state.nodes.indexOf(node);
    if (indexOfRemovedNode > -1) {
      this.state.nodes.splice(indexOfRemovedNode, 1);
      if (this.state.nodeDetails[node.id]) {
        delete this.state.nodeDetails[node.id];
      }
    }
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

  static formatNode(rawNode) {
    const { id, url, primary, current, enabled } = rawNode;
    return {
      id,
      url,
      primary,
      current,
      enabled,
      nodeActionActive: false,
      basePath: rawNode._links.self,
      repairPath: rawNode._links.repair,
      editPath: rawNode.web_edit_url,
      statusPath: rawNode._links.status,
    };
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
      missingOAuthApplication: rawNodeDetails.missing_oauth_application || false,
      storageShardsMatch: rawNodeDetails.storage_shards_match,
      syncStatusUnavailable: rawNodeDetails.sync_status_unavailable || false,
      replicationSlots: {
        totalCount: rawNodeDetails.replication_slots_count || 0,
        successCount: rawNodeDetails.replication_slots_used_count || 0,
        failureCount: 0,
      },
      repositories: {
        totalCount: rawNodeDetails.repositories_count || 0,
        successCount: rawNodeDetails.repositories_synced_count || 0,
        failureCount: rawNodeDetails.repositories_failed_count || 0,
      },
      wikis: {
        totalCount: rawNodeDetails.wikis_count || 0,
        successCount: rawNodeDetails.wikis_synced_count || 0,
        failureCount: rawNodeDetails.wikis_failed_count || 0,
      },
      repositoryVerificationEnabled: rawNodeDetails.repository_verification_enabled,
      verifiedRepositories: {
        totalCount: rawNodeDetails.repositories_count || 0,
        successCount: rawNodeDetails.repositories_verified_count || 0,
        failureCount: rawNodeDetails.repositories_verification_failed_count || 0,
      },
      verifiedWikis: {
        totalCount: rawNodeDetails.wikis_count || 0,
        successCount: rawNodeDetails.wikis_verified_count || 0,
        failureCount: rawNodeDetails.wikis_verification_failed_count || 0,
      },
      lfs: {
        totalCount: rawNodeDetails.lfs_objects_count || 0,
        successCount: rawNodeDetails.lfs_objects_synced_count || 0,
        failureCount: rawNodeDetails.lfs_objects_failed_count || 0,
      },
      jobArtifacts: {
        totalCount: rawNodeDetails.job_artifacts_count || 0,
        successCount: rawNodeDetails.job_artifacts_synced_count || 0,
        failureCount: rawNodeDetails.job_artifacts_failed_count || 0,
      },
      attachments: {
        totalCount: rawNodeDetails.attachments_count || 0,
        successCount: rawNodeDetails.attachments_synced_count || 0,
        failureCount: rawNodeDetails.attachments_failed_count || 0,
      },
      lastEvent: {
        id: rawNodeDetails.last_event_id || 0,
        timeStamp: rawNodeDetails.last_event_timestamp,
      },
      cursorLastEvent: {
        id: rawNodeDetails.cursor_last_event_id || 0,
        timeStamp: rawNodeDetails.cursor_last_event_timestamp,
      },
      selectiveSyncType: rawNodeDetails.selective_sync_type,
      dbReplicationLag: rawNodeDetails.db_replication_lag_seconds,
    };
  }
}
