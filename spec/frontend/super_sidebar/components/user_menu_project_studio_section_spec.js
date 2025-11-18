import { GlDisclosureDropdownGroup, GlToggle } from '@gitlab/ui';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import UserMenuProjectStudioSection from '~/super_sidebar/components/user_menu_project_studio_section.vue';
import { createAlert } from '~/alert';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import waitForPromises from 'helpers/wait_for_promises';
import { useMockInternalEventsTracking } from 'helpers/tracking_internal_events_helper';

jest.mock('~/alert');
jest.mock('~/sentry/sentry_browser_wrapper');

const setProjectStudioEnabledMutationResponse = {
  data: {
    userPreferencesUpdate: {
      userPreferences: {
        projectStudioEnabled: true,
      },
    },
  },
};

describe('UserMenuProjectStudioSection', () => {
  let wrapper;

  const findDropdownGroup = () => wrapper.findComponent(GlDisclosureDropdownGroup);
  const findToggleItem = () => wrapper.findByTestId('toggle-project-studio-link');
  const findFeedbackItem = () => wrapper.findByTestId('project-studio-feedback-link');
  const findToggle = () => wrapper.findComponent(GlToggle);

  const { bindInternalEventDocument } = useMockInternalEventsTracking();

  const createComponent = (provide = {}) => {
    wrapper = mountExtended(UserMenuProjectStudioSection, {
      provide: {
        isImpersonating: false,
        projectStudioEnabled: true,
        ...provide,
      },
      mocks: {
        $apollo: {
          mutate: jest.fn(),
        },
      },
    });
  };

  describe('when project studio is disabled', () => {
    beforeEach(() => {
      createComponent({ projectStudioEnabled: false });
    });

    it('renders the dropdown group with preview label', () => {
      expect(findDropdownGroup().exists()).toBe(true);
      expect(findDropdownGroup().props('bordered')).toBe(true);
    });

    it('renders the toggle item with correct text and state', () => {
      expect(findToggleItem().exists()).toBe(true);
      expect(findToggle().props('value')).toBe(false);
    });
  });

  describe('when project studio is enabled', () => {
    beforeEach(() => {
      createComponent({ projectStudioEnabled: true });
    });

    it('renders the toggle with enabled state', () => {
      expect(findToggle().props('value')).toBe(true);
    });
  });

  describe('when toggling project studio', () => {
    beforeEach(() => {
      createComponent({ projectStudioEnabled: false });
    });

    it('calls the mutation with correct variables when enabling', async () => {
      const mutateSpy = jest.fn().mockResolvedValue(setProjectStudioEnabledMutationResponse);
      wrapper.vm.$apollo.mutate = mutateSpy;

      findToggleItem().trigger('click');
      await waitForPromises();

      expect(mutateSpy).toHaveBeenCalledWith({
        mutation: expect.any(Object),
        variables: {
          projectStudioEnabled: true,
        },
        update: expect.any(Function),
      });
    });

    it('calls the mutation with correct variables when disabling', async () => {
      createComponent({ projectStudioEnabled: true });
      const mutateSpy = jest.fn().mockResolvedValue(setProjectStudioEnabledMutationResponse);
      wrapper.vm.$apollo.mutate = mutateSpy;

      findToggleItem().trigger('click');
      await waitForPromises();

      expect(mutateSpy).toHaveBeenCalledWith({
        mutation: expect.any(Object),
        variables: {
          projectStudioEnabled: false,
        },
        update: expect.any(Function),
      });
    });

    it('tracks opt-in event when enabling project studio', async () => {
      const mutateSpy = jest.fn().mockResolvedValue(setProjectStudioEnabledMutationResponse);
      wrapper.vm.$apollo.mutate = mutateSpy;
      const { trackEventSpy } = bindInternalEventDocument(wrapper.element);

      findToggleItem().trigger('click');
      await waitForPromises();

      expect(trackEventSpy).toHaveBeenCalledWith('opt_in_project_studio', {}, undefined);
    });

    it('tracks opt-out event when disabling project studio', async () => {
      createComponent({ projectStudioEnabled: true });
      const mutateSpy = jest.fn().mockResolvedValue(setProjectStudioEnabledMutationResponse);
      wrapper.vm.$apollo.mutate = mutateSpy;
      const { trackEventSpy } = bindInternalEventDocument(wrapper.element);

      findToggleItem().trigger('click');
      await waitForPromises();

      expect(trackEventSpy).toHaveBeenCalledWith('opt_out_project_studio', {}, undefined);
    });

    it('tracks event before making the mutation call', async () => {
      const mutateSpy = jest.fn().mockResolvedValue(setProjectStudioEnabledMutationResponse);
      wrapper.vm.$apollo.mutate = mutateSpy;
      const { trackEventSpy } = bindInternalEventDocument(wrapper.element);

      findToggleItem().trigger('click');

      // Track should be called immediately, before the async mutation
      expect(trackEventSpy).toHaveBeenCalledWith('opt_in_project_studio', {}, undefined);

      await waitForPromises();

      expect(mutateSpy).toHaveBeenCalled();
    });

    it('still tracks event even if mutation fails', async () => {
      const error = new Error('Mutation failed');
      const mutateSpy = jest.fn().mockRejectedValue(error);
      wrapper.vm.$apollo.mutate = mutateSpy;
      const { trackEventSpy } = bindInternalEventDocument(wrapper.element);

      findToggleItem().trigger('click');
      await waitForPromises();

      expect(trackEventSpy).toHaveBeenCalledWith('opt_in_project_studio', {}, undefined);
      expect(createAlert).toHaveBeenCalledWith({
        message: 'Something went wrong. Please try again.',
      });
      expect(Sentry.captureException).toHaveBeenCalledWith(error);
    });

    // eslint-disable-next-line jest/no-disabled-tests
    it.skip('reloads the page on successful mutation', async () => {
      const reloadSpy = jest.spyOn(window.location.reload, 'reload').mockImplementation(() => {});

      const mutateSpy = jest.fn().mockResolvedValue(setProjectStudioEnabledMutationResponse);
      wrapper.vm.$apollo.mutate = mutateSpy;

      findToggleItem().trigger('click');
      await waitForPromises();

      expect(reloadSpy).toHaveBeenCalled();
      reloadSpy.mockRestore();
    });

    it('shows alert and captures exception on mutation error', async () => {
      const error = new Error('Mutation failed');
      const mutateSpy = jest.fn().mockRejectedValue(error);
      wrapper.vm.$apollo.mutate = mutateSpy;

      findToggleItem().trigger('click');
      await waitForPromises();

      expect(createAlert).toHaveBeenCalledWith({
        message: 'Something went wrong. Please try again.',
      });
      expect(Sentry.captureException).toHaveBeenCalledWith(error);
    });
  });

  describe('feedback link', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders the provide feedback item', () => {
      const feedbackItem = findFeedbackItem();
      expect(feedbackItem.exists()).toBe(true);
    });

    it('provides correct feedback URL', () => {
      const feedbackItem = findFeedbackItem();
      expect(feedbackItem.props('href')).toBe(
        'https://gitlab.com/gitlab-org/gitlab/-/issues/577554',
      );
    });
  });
});
