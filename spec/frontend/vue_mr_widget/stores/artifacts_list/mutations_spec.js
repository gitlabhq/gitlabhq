import * as types from '~/vue_merge_request_widget/stores/artifacts_list/mutation_types';
import mutations from '~/vue_merge_request_widget/stores/artifacts_list/mutations';
import state from '~/vue_merge_request_widget/stores/artifacts_list/state';

describe('Artifacts Store Mutations', () => {
  let stateCopy;

  beforeEach(() => {
    stateCopy = state();
  });

  describe('SET_ENDPOINT', () => {
    it('should set endpoint', () => {
      mutations[types.SET_ENDPOINT](stateCopy, 'endpoint.json');

      expect(stateCopy.endpoint).toEqual('endpoint.json');
    });
  });

  describe('REQUEST_ARTIFACTS', () => {
    it('should set isLoading to true', () => {
      mutations[types.REQUEST_ARTIFACTS](stateCopy);

      expect(stateCopy.isLoading).toEqual(true);
    });
  });

  describe('REECEIVE_ARTIFACTS_SUCCESS', () => {
    const artifacts = [
      {
        text: 'result.txt',
        url: 'asda',
        job_name: 'generate-artifact',
        job_path: 'asda',
      },
      {
        text: 'file.txt',
        url: 'asda',
        job_name: 'generate-artifact',
        job_path: 'asda',
      },
    ];

    beforeEach(() => {
      mutations[types.RECEIVE_ARTIFACTS_SUCCESS](stateCopy, artifacts);
    });

    it('should set isLoading to false', () => {
      expect(stateCopy.isLoading).toEqual(false);
    });

    it('should set hasError to false', () => {
      expect(stateCopy.hasError).toEqual(false);
    });

    it('should set list of artifacts', () => {
      expect(stateCopy.artifacts).toEqual(artifacts);
    });
  });

  describe('RECEIVE_ARTIFACTS_ERROR', () => {
    beforeEach(() => {
      mutations[types.RECEIVE_ARTIFACTS_ERROR](stateCopy);
    });

    it('should set isLoading to false', () => {
      expect(stateCopy.isLoading).toEqual(false);
    });

    it('should set hasError to true', () => {
      expect(stateCopy.hasError).toEqual(true);
    });

    it('should set list of artifacts as empty array', () => {
      expect(stateCopy.artifacts).toEqual([]);
    });
  });
});
