import Vue from 'vue';
import VueApollo from 'vue-apollo';

import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';

import { createAlert } from '~/alert';
import CiCdCatalogWrapper from '~/releases/components/ci_cd_catalog_wrapper.vue';

import getCiCatalogSettingsQuery from '~/ci/catalog/graphql/queries/get_ci_catalog_settings.query.graphql';
import catalogReleasesQuery from '~/releases/graphql/queries/catalog_releases.query.graphql';
import { catalogReleasesResponse, generateCatalogSettingsResponse } from '../mock_data';

Vue.use(VueApollo);
jest.mock('~/alert');

describe('CiCdCatalogWrapper', () => {
  let wrapper;
  let catalogSettingsHandler;
  let catalogReleasesHandler;

  const defaultProps = {
    releasePath: '/root/project/-/tags/1.0.7',
  };
  const projectPath = 'project/path';

  const createComponent = async ({ props = {}, scopedSlots = { default: `<div></div>` } } = {}) => {
    const handlers = [
      [getCiCatalogSettingsQuery, catalogSettingsHandler],
      [catalogReleasesQuery, catalogReleasesHandler],
    ];

    wrapper = shallowMountExtended(CiCdCatalogWrapper, {
      apolloProvider: createMockApollo(handlers),
      propsData: {
        ...defaultProps,
        ...props,
      },
      provide: { projectPath },
      scopedSlots,
    });

    await waitForPromises();
  };

  const findReleaseButton = () => wrapper.findByTestId('release-button');
  const findSettingsButton = () => wrapper.findByTestId('settings-button');

  describe('settings data', () => {
    const scopedSlots = {
      default: `
        <button data-testid="settings-button" :disabled="props.isCiCdCatalogProject">Depends on setting</button>
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
        expect(findSettingsButton().exists()).toBe(true);
      });

      describe('when project is not a CI/CD Catalog project', () => {
        beforeEach(async () => {
          catalogSettingsHandler = jest.fn().mockResolvedValue(generateCatalogSettingsResponse);
          await createComponent({ scopedSlots });
        });

        it('renders button as enabled', () => {
          expect(findSettingsButton().attributes('disabled')).toBe(undefined);
        });
      });

      describe('when project is a CI/CD Catalog project', () => {
        beforeEach(async () => {
          catalogSettingsHandler = jest
            .fn()
            .mockResolvedValue(generateCatalogSettingsResponse(true));
          await createComponent({ scopedSlots });
        });

        it('renders button as disabled', () => {
          expect(findSettingsButton().attributes('disabled')).toBe('disabled');
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

  describe('release data', () => {
    const scopedSlots = {
      default: `
        <button data-testid="release-button" :href="props.detailsPagePath">{{props.isCatalogRelease}}</button>
        `,
    };

    describe('when project is not a CI/CD Catalog project', () => {
      beforeEach(async () => {
        catalogSettingsHandler = jest.fn().mockResolvedValue(generateCatalogSettingsResponse());
        catalogReleasesHandler = jest.fn().mockResolvedValue(catalogReleasesResponse);

        await createComponent({ scopedSlots });
      });

      it('does not fire the catalog releases query', () => {
        expect(catalogReleasesHandler).not.toHaveBeenCalled();
      });
    });

    describe('when project is a CI/CD Catalog project', () => {
      beforeEach(async () => {
        catalogSettingsHandler = jest.fn().mockResolvedValue(generateCatalogSettingsResponse(true));
        catalogReleasesHandler = await jest.fn().mockResolvedValue(catalogReleasesResponse);

        await createComponent({ scopedSlots });
      });

      it('fires the catalog releases query', () => {
        expect(catalogReleasesHandler).toHaveBeenCalledTimes(1);
      });

      describe('when release is published in the catalog', () => {
        it('sets isCatalogRelease to true', () => {
          expect(findReleaseButton().text()).toBe('true');
        });

        it('assigns project path to button', () => {
          expect(findReleaseButton().attributes('href')).toBe(`/explore/catalog/${projectPath}`);
        });
      });
    });

    describe('when release is not published in the catalog', () => {
      beforeEach(async () => {
        await createComponent({ props: { releasePath: '/not/included' }, scopedSlots });
      });

      it('sets isCatalogRelease to false', () => {
        expect(findReleaseButton().text()).toBe('false');
      });

      it('does not assign project path to button', () => {
        expect(findReleaseButton().attributes('href')).toBe('');
      });
    });

    describe('when releases query fails', () => {
      beforeEach(async () => {
        catalogReleasesHandler = jest.fn().mockRejectedValue();
        await createComponent();
      });

      it('calls createAlert with the correct message', () => {
        expect(createAlert).toHaveBeenCalled();
        expect(createAlert).toHaveBeenCalledWith({
          message: 'There was a problem fetching the CI/CD Catalog releases.',
        });
      });
    });
  });
});
