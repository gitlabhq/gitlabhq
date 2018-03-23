import securityState from 'ee/vue_shared/security_reports/helpers/state';
import {
  setSastReport,
} from 'ee/vue_shared/security_reports/helpers/utils';

export default class PipelineStore {
  constructor() {
    this.state = {};

    this.state.pipeline = {};

    /* EE only */
    this.state.securityReports = securityState;
  }

  storePipeline(pipeline = {}) {
    this.state.pipeline = pipeline;
  }

  /**
   * EE only
  */
  storeSastReport(data, blobPath) {
    Object.assign(
      this.state.securityReports.sast,
      setSastReport({ head: data, headBlobPath: blobPath }),
    );
  }

  storeDependencyScanningReport(data, blobPath) {
    Object.assign(
      this.state.securityReports.dependencyScanning,
      setSastReport({ head: data, headBlobPath: blobPath }),
    );
  }
}
