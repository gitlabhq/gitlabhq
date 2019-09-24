import testAction from 'helpers/vuex_action_helper';

import * as awsServicesFacade from '~/create_cluster/eks_cluster/services/aws_services_facade';
import createState from '~/create_cluster/eks_cluster/store/state';
import * as types from '~/create_cluster/eks_cluster/store/mutation_types';
import * as actions from '~/create_cluster/eks_cluster/store/actions';

describe('EKS Cluster Store Actions', () => {
  const regions = [{ name: 'region 1' }];

  describe('fetchRegions', () => {
    describe('on success', () => {
      beforeEach(() => {
        jest.spyOn(awsServicesFacade, 'fetchRegions').mockResolvedValueOnce(regions);
      });

      it('dispatches success with received regions', () =>
        testAction(
          actions.fetchRegions,
          null,
          createState(),
          [],
          [
            { type: 'requestRegions' },
            {
              type: 'receiveRegionsSuccess',
              payload: { regions },
            },
          ],
        ));
    });

    describe('on failure', () => {
      const error = new Error('Could not fetch regions');

      beforeEach(() => {
        jest.spyOn(awsServicesFacade, 'fetchRegions').mockRejectedValueOnce(error);
      });

      it('dispatches success with received regions', () =>
        testAction(
          actions.fetchRegions,
          null,
          createState(),
          [],
          [
            { type: 'requestRegions' },
            {
              type: 'receiveRegionsError',
              payload: { error },
            },
          ],
        ));
    });
  });

  describe('requestRegions', () => {
    it(`commits ${types.REQUEST_REGIONS} mutation`, () =>
      testAction(actions.requestRegions, null, createState(), [{ type: types.REQUEST_REGIONS }]));
  });

  describe('receiveRegionsSuccess', () => {
    it(`commits ${types.RECEIVE_REGIONS_SUCCESS} mutation`, () =>
      testAction(actions.receiveRegionsSuccess, { regions }, createState(), [
        {
          type: types.RECEIVE_REGIONS_SUCCESS,
          payload: {
            regions,
          },
        },
      ]));
  });

  describe('receiveRegionsError', () => {
    it(`commits ${types.RECEIVE_REGIONS_ERROR} mutation`, () => {
      const error = new Error('Error fetching regions');

      testAction(actions.receiveRegionsError, { error }, createState(), [
        {
          type: types.RECEIVE_REGIONS_ERROR,
          payload: {
            error,
          },
        },
      ]);
    });
  });

  describe('setRegion', () => {
    it(`commits ${types.SET_REGION} mutation`, () => {
      const region = { name: 'west-1' };

      testAction(actions.setRegion, { region }, createState(), [
        { type: types.SET_REGION, payload: { region } },
      ]);
    });
  });
});
