import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import { GlAlert } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';

import CrudComponent from '~/vue_shared/components/crud_component.vue';
import getWorkItemDesignListQuery from '~/work_items/components/design_management/graphql/design_collection.query.graphql';
import archiveDesignMutation from '~/work_items/components/design_management/graphql/archive_design.mutation.graphql';
import DesignItem from '~/work_items/components/design_management/design_item.vue';
import DesignWidget from '~/work_items/components/design_management/design_management_widget.vue';
import { createMockDirective } from 'helpers/vue_mock_directive';
import { designArchiveError } from '~/work_items/components/design_management/constants';

import {
  designCollectionResponse,
  mockDesign,
  mockDesign2,
  mockArchiveDesignMutationResponse,
  allDesignsArchivedResponse,
} from './mock_data';

jest.mock('~/alert');
Vue.use(VueApollo);

const PREVIOUS_VERSION_ID = 2;
const ALL_DESIGNS_ARCHIVED_TEXT = 'All designs have been archived.';

const designRouteFactory = (versionId) => ({
  path: `?version=${versionId}`,
  query: {
    version: `${versionId}`,
  },
});

const MOCK_ROUTE = {
  path: '/',
  query: {},
};

describe('DesignWidget', () => {
  let wrapper;
  const workItemId = 'gid://gitlab/WorkItem/1';

  const oneDesignQueryHandler = jest.fn().mockResolvedValue(designCollectionResponse());
  const twoDesignsQueryHandler = jest
    .fn()
    .mockResolvedValue(designCollectionResponse([mockDesign, mockDesign2]));
  const archiveDesignSuccessMutationHandler = jest
    .fn()
    .mockResolvedValue(mockArchiveDesignMutationResponse);
  const archiveDesignMutationError = jest.fn().mockRejectedValue(new Error('Mutation failed'));
  const allDesignsArchivedQueryHandler = jest.fn().mockResolvedValue(allDesignsArchivedResponse());

  const findWidgetWrapper = () => wrapper.findComponent(CrudComponent);
  const findAllDesignItems = () => wrapper.findAllComponents(DesignItem);
  const findArchiveButton = () => wrapper.findByTestId('archive-button');
  const findSelectAllButton = () => wrapper.findByTestId('select-all-designs-button');
  const findDesignCheckboxes = () => wrapper.findAllByTestId('design-checkbox');
  const findAlert = () => wrapper.findComponent(GlAlert);

  function createComponent({
    designCollectionQueryHandler = oneDesignQueryHandler,
    archiveDesignMutationHandler = archiveDesignSuccessMutationHandler,
    routeArg = MOCK_ROUTE,
    uploadError = null,
  } = {}) {
    wrapper = shallowMountExtended(DesignWidget, {
      apolloProvider: createMockApollo([
        [getWorkItemDesignListQuery, designCollectionQueryHandler],
        [archiveDesignMutation, archiveDesignMutationHandler],
      ]),
      propsData: {
        workItemId,
        uploadError,
      },
      directives: {
        GlTooltip: createMockDirective('gl-tooltip'),
      },
      mocks: {
        $route: routeArg,
      },
      provide: {
        fullPath: 'gitlab-org/gitlab-shell',
      },
      stubs: {
        RouterView: true,
      },
    });
  }

  describe('when work item has designs', () => {
    beforeEach(() => {
      createComponent();
      return waitForPromises();
    });

    it('calls design collection query without version by default', () => {
      expect(oneDesignQueryHandler).toHaveBeenCalledWith({
        id: workItemId,
        atVersion: null,
      });
    });

    it('renders widget wrapper', () => {
      expect(findWidgetWrapper().exists()).toBe(true);
    });

    it('renders Select All and Archive Selected buttons', () => {
      expect(findArchiveButton().exists()).toBe(true);
      expect(findSelectAllButton().exists()).toBe(true);
    });

    it('does not render Select All and Archive Selected buttons if the current version is not the latest', async () => {
      createComponent({ routeArg: designRouteFactory(PREVIOUS_VERSION_ID) });

      await waitForPromises();

      expect(findArchiveButton().exists()).toBe(false);
      expect(findSelectAllButton().exists()).toBe(false);
    });

    it('adds all designs to selected designs when Select All button is clicked', async () => {
      findSelectAllButton().vm.$emit('click');

      await nextTick();
      expect(findArchiveButton().props().hasSelectedDesigns).toBe(true);
      expect(findSelectAllButton().text()).toBe('Deselect all');
    });

    it('archives a design', async () => {
      findDesignCheckboxes().at(0).trigger('click');

      await nextTick();

      findArchiveButton().vm.$emit('archive-selected-designs');
      await waitForPromises();

      expect(archiveDesignSuccessMutationHandler).toHaveBeenCalled();
    });

    it('throws error if archive a design query fails', async () => {
      createComponent({ archiveDesignMutationHandler: archiveDesignMutationError });
      await waitForPromises();

      findArchiveButton().vm.$emit('archive-selected-designs');
      await waitForPromises();

      expect(findAlert().exists()).toBe(true);
      expect(findAlert().text()).toBe(designArchiveError(2));
    });
  });

  it('calls design collection query with version passed in route', async () => {
    createComponent({ routeArg: designRouteFactory(PREVIOUS_VERSION_ID) });

    await waitForPromises();

    expect(oneDesignQueryHandler).toHaveBeenCalledWith({
      id: workItemId,
      atVersion: `gid://gitlab/DesignManagement::Version/${PREVIOUS_VERSION_ID}`,
    });
  });

  it.each`
    length | queryHandler
    ${1}   | ${oneDesignQueryHandler}
    ${2}   | ${twoDesignsQueryHandler}
  `('renders $length designs and checkboxes', async ({ length, queryHandler }) => {
    createComponent({ designCollectionQueryHandler: queryHandler });
    await waitForPromises();

    expect(queryHandler).toHaveBeenCalled();
    expect(findAllDesignItems().length).toBe(length);
    expect(findDesignCheckboxes().length).toBe(length);
  });

  it('renders text if all designs are archived', async () => {
    createComponent({ designCollectionQueryHandler: allDesignsArchivedQueryHandler });
    await waitForPromises();

    expect(findAllDesignItems().length).toBe(0);
    expect(wrapper.text()).toContain(ALL_DESIGNS_ARCHIVED_TEXT);
  });

  it('dismisses error passed as prop', async () => {
    createComponent({ uploadError: 'Error uploading a new design. Please try again.' });
    await waitForPromises();

    expect(findAlert().exists()).toBe(true);
    findAlert().vm.$emit('dismiss');

    expect(wrapper.emitted('dismissError')).toHaveLength(1);
  });
});
