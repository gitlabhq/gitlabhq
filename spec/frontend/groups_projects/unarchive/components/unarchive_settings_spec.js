import { GlButton, GlCard, GlIcon, GlLink } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { nextTick } from 'vue';
import UnarchiveSettings from '~/groups_projects/unarchive/components/unarchive_settings.vue';
import { RESOURCE_TYPES } from '~/groups_projects/constants';
import { unarchiveProject } from '~/api/projects_api';
import { unarchiveGroup } from '~/api/groups_api';
import waitForPromises from 'helpers/wait_for_promises';
import { createAlert } from '~/alert';
import { visitUrl } from '~/lib/utils/url_utility';
import { createMockDirective, getBinding } from 'helpers/vue_mock_directive';
import { useMockInternalEventsTracking } from 'helpers/tracking_internal_events_helper';

jest.mock('~/lib/utils/url_utility');
jest.mock('~/alert');
jest.mock('~/api/groups_api');
jest.mock('~/api/projects_api');

describe('UnarchiveSettings', () => {
  let wrapper;

  const { bindInternalEventDocument } = useMockInternalEventsTracking();

  const unarchiveFuncByType = {
    [RESOURCE_TYPES.GROUP]: unarchiveGroup,
    [RESOURCE_TYPES.PROJECT]: unarchiveProject,
  };

  const defaultProps = {
    resourceType: RESOURCE_TYPES.GROUP,
    resourcePath: '/groups/test-group',
    resourceId: '123',
    ancestorsArchived: false,
    helpPath: '/help-path',
  };

  const createComponent = ({ props = {} } = {}) => {
    wrapper = shallowMount(UnarchiveSettings, {
      propsData: { ...defaultProps, ...props },
      directives: {
        GlTooltip: createMockDirective('gl-tooltip'),
      },
    });
  };

  const findGlCard = () => wrapper.findComponent(GlCard);
  const findGlButton = () => wrapper.findComponent(GlButton);
  const findGlIcon = () => wrapper.findComponent(GlIcon);
  const findGlLink = () => wrapper.findComponent(GlLink);

  describe.each(Object.values(RESOURCE_TYPES))('for %s', (resourceType) => {
    it('renders card header', () => {
      createComponent({ props: { resourceType } });

      expect(findGlCard().text()).toContain(`Unarchive ${resourceType}`);
    });

    it('renders card body', () => {
      createComponent({ props: { resourceType } });

      expect(findGlCard().text()).toContain(
        `Restore your ${resourceType} to an active state. You'll be able to modify its content and settings again.`,
      );
    });

    describe('when helpPath is provided', () => {
      it('renders helpLink', () => {
        createComponent({ props: { resourceType } });

        expect(findGlLink().text()).toBe(`How do I unarchive a ${resourceType}?`);
      });
    });

    describe('when helpPath is not provided', () => {
      it('does not render helpLink', () => {
        createComponent({ props: { resourceType, helpPath: null } });

        expect(findGlLink().exists()).toBe(false);
      });
    });

    describe('when ancestorsArchived is false', () => {
      it('renders unarchive button', () => {
        createComponent({ props: { resourceType } });

        expect(findGlButton().text()).toBe('Unarchive');
      });

      describe('when unarchive button is clicked', () => {
        const unarchiveFunc = unarchiveFuncByType[resourceType];
        const clickUnarchiveButton = () => findGlButton().vm.$emit('click');

        beforeEach(() => {
          createComponent({ props: { resourceType } });
        });

        it('tracks internal event', () => {
          const { triggerEvent, trackEventSpy } = bindInternalEventDocument(wrapper.element);

          triggerEvent(findGlButton().element);

          expect(trackEventSpy).toHaveBeenCalledWith('archive_namespace_in_settings', {
            label: resourceType,
            property: 'unarchive',
          });
        });

        it('calls unarchiveFunc', () => {
          clickUnarchiveButton();

          expect(unarchiveFunc).toHaveBeenCalledWith(defaultProps.resourceId);
        });

        it('sets button loading state', async () => {
          clickUnarchiveButton();
          await nextTick();

          expect(findGlButton().props('loading')).toBe(true);
        });

        describe('when API call is successful', () => {
          beforeEach(async () => {
            unarchiveFunc.mockResolvedValueOnce();
            clickUnarchiveButton();
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
            unarchiveFunc.mockRejectedValue(error);
            clickUnarchiveButton();
            await waitForPromises();
          });

          it('stops confirm button loading state', () => {
            expect(findGlButton().props('loading')).toBe(false);
          });

          it('shows error alert', () => {
            expect(createAlert).toHaveBeenCalledWith({
              message: `An error occurred while unarchiving the ${resourceType}. Please refresh the page and try again.`,
              error,
              captureError: true,
            });
          });
        });
      });
    });

    describe('when ancestorsArchived is true', () => {
      beforeEach(() => {
        createComponent({ props: { resourceType, ancestorsArchived: true } });
      });

      it('renders cancel icon with tooltip', () => {
        const icon = findGlIcon();
        const tooltipDirective = getBinding(icon.element, 'gl-tooltip');

        expect(icon.props('name')).toBe('cancel');
        expect(tooltipDirective.value).toBe(
          `To unarchive this ${resourceType}, you must unarchive its parent group.`,
        );
      });

      it('does not render unarchive button', () => {
        expect(findGlButton().exists()).toBe(false);
      });
    });
  });
});
