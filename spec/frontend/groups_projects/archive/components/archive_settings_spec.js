import { GlButton, GlCard, GlLink } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { nextTick } from 'vue';
import ArchiveSettings from '~/groups_projects/archive/components/archive_settings.vue';
import { RESOURCE_TYPES } from '~/groups_projects/constants';
import { archiveProject } from '~/api/projects_api';
import { archiveGroup } from '~/api/groups_api';
import waitForPromises from 'helpers/wait_for_promises';
import { createAlert } from '~/alert';
import { visitUrl } from '~/lib/utils/url_utility';
import { useMockInternalEventsTracking } from 'helpers/tracking_internal_events_helper';

jest.mock('~/lib/utils/url_utility');
jest.mock('~/alert');
jest.mock('~/api/groups_api');
jest.mock('~/api/projects_api');

describe('ArchiveSettings', () => {
  let wrapper;

  const { bindInternalEventDocument } = useMockInternalEventsTracking();

  const archiveFuncByType = {
    [RESOURCE_TYPES.GROUP]: archiveGroup,
    [RESOURCE_TYPES.PROJECT]: archiveProject,
  };

  const defaultProps = {
    resourceType: RESOURCE_TYPES.GROUP,
    resourcePath: '/groups/test-group',
    resourceId: '123',
    helpPath: '/help-path',
  };

  const createComponent = ({ props = {} } = {}) => {
    wrapper = shallowMount(ArchiveSettings, {
      propsData: { ...defaultProps, ...props },
    });
  };

  const findGlCard = () => wrapper.findComponent(GlCard);
  const findGlButton = () => wrapper.findComponent(GlButton);
  const findGlLink = () => wrapper.findComponent(GlLink);

  describe.each(Object.values(RESOURCE_TYPES))('for %s', (resourceType) => {
    it('renders card header', () => {
      createComponent({ props: { resourceType } });

      expect(findGlCard().text()).toContain(`Archive ${resourceType}`);
    });

    it('renders card body', () => {
      createComponent({ props: { resourceType } });

      expect(findGlCard().text()).toContain(
        `Make your ${resourceType} read-only. You can still access its data, work items, and merge requests.`,
      );
    });

    describe('when helpPath is provided', () => {
      it('renders helpLink', () => {
        createComponent({ props: { resourceType } });

        expect(findGlLink().text()).toBe(`How do I archive a ${resourceType}?`);
      });
    });

    describe('when helpPath is not provided', () => {
      it('does not render helpLink', () => {
        createComponent({ props: { resourceType, helpPath: null } });

        expect(findGlLink().exists()).toBe(false);
      });
    });

    it('renders archive button', () => {
      createComponent({ props: { resourceType } });

      expect(findGlButton().text()).toBe('Archive');
    });

    describe('when archive button is clicked', () => {
      const archiveFunc = archiveFuncByType[resourceType];
      const clickArchiveButton = () => findGlButton().vm.$emit('click');

      beforeEach(() => {
        createComponent({ props: { resourceType } });
      });

      it('tracks internal event', () => {
        const { triggerEvent, trackEventSpy } = bindInternalEventDocument(wrapper.element);

        triggerEvent(findGlButton().element);

        expect(trackEventSpy).toHaveBeenCalledWith('archive_namespace_in_settings', {
          label: resourceType,
          property: 'archive',
        });
      });

      it('calls archiveFunc', () => {
        clickArchiveButton();

        expect(archiveFunc).toHaveBeenCalledWith(defaultProps.resourceId);
      });

      it('sets button loading state', async () => {
        clickArchiveButton();
        await nextTick();

        expect(findGlButton().props('loading')).toBe(true);
      });

      describe('when API call is successful', () => {
        beforeEach(async () => {
          archiveFunc.mockResolvedValueOnce();
          clickArchiveButton();
          await waitForPromises();
        });

        it('does not create alert', () => {
          expect(createAlert).not.toHaveBeenCalled();
        });

        it('trigger stays in loading state', () => {
          expect(findGlButton().props('loading')).toBe(true);
        });

        it('visits resourcePath', () => {
          expect(visitUrl).toHaveBeenCalledWith(defaultProps.resourcePath);
        });
      });

      describe('when API call is not successful', () => {
        const error = new Error();

        beforeEach(async () => {
          archiveFunc.mockRejectedValue(error);
          clickArchiveButton();
          await waitForPromises();
        });

        it('stops confirm button loading state', () => {
          expect(findGlButton().props('loading')).toBe(false);
        });

        it('shows error alert', () => {
          expect(createAlert).toHaveBeenCalledWith({
            message: `An error occurred while archiving the ${resourceType}. Please refresh the page and try again.`,
            error,
            captureError: true,
          });
        });
      });
    });
  });
});
