import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { shallowMount } from '@vue/test-utils';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';

import { createAlert } from '~/alert';
import CiCdCatalogWrapper from '~/releases/components/ci_cd_catalog_wrapper.vue';

import getCiCatalogSettingsQuery from '~/ci/catalog/graphql/queries/get_ci_catalog_settings.query.graphql';
import { generateCatalogSettingsResponse } from '../mock_data';

Vue.use(VueApollo);
jest.mock('~/alert');

describe('CiCdCatalogWrapper', () => {
  let wrapper;
  let catalogSettingsHandler;

  const createComponent = async ({ scopedSlots } = {}) => {
    const handlers = [[getCiCatalogSettingsQuery, catalogSettingsHandler]];

    wrapper = shallowMount(CiCdCatalogWrapper, {
      apolloProvider: createMockApollo(handlers),
      provide: {
        projectPath: 'project/path',
      },
      scopedSlots,
    });

    await waitForPromises();
  };

  const findButton = () => wrapper.find('button');

  describe('settings data', () => {
    const scopedSlots = {
      default: `
        <button :disabled="props.isCiCdCatalogProject">New release</button>
        `,
    };

    describe('on load', () => {
      beforeEach(async () => {
        catalogSettingsHandler = jest.fn().mockResolvedValue(generateCatalogSettingsResponse);
        await createComponent({ scopedSlots });
      });

      it('fetches data from settings query', () => {
        expect(catalogSettingsHandler).toHaveBeenCalledTimes(1);
      });

      it('renders button', () => {
        expect(findButton().exists()).toBe(true);
      });
    });

    describe('when project is not a CI/CD Catalog project', () => {
      beforeEach(async () => {
        catalogSettingsHandler = jest.fn().mockResolvedValue(generateCatalogSettingsResponse);
        await createComponent({ scopedSlots });
      });

      it('renders button as enabled', () => {
        expect(findButton().attributes('disabled')).toBe(undefined);
      });
    });

    describe('when project is a CI/CD Catalog project', () => {
      beforeEach(async () => {
        catalogSettingsHandler = jest.fn().mockResolvedValue(generateCatalogSettingsResponse(true));
        await createComponent({ scopedSlots });
      });

      it('renders button as disabled', () => {
        expect(findButton().attributes('disabled')).toBe('disabled');
      });
    });

    describe('when settings query fails', () => {
      beforeEach(async () => {
        catalogSettingsHandler = jest.fn().mockRejectedValue();
        await createComponent({ scopedSlots });
      });

      it('calls createAlert with the correct message', () => {
        expect(createAlert).toHaveBeenCalled();
        expect(createAlert).toHaveBeenCalledWith({
          message: 'There was a problem fetching the CI/CD Catalog setting.',
        });
      });
    });
  });
});
