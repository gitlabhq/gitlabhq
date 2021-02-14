import { GlButton, GlEmptyState, GlLoadingIcon } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import Success from '~/static_site_editor/pages/success.vue';
import { HOME_ROUTE } from '~/static_site_editor/router/constants';
import { savedContentMeta, returnUrl, sourcePath } from '../mock_data';

describe('~/static_site_editor/pages/success.vue', () => {
  const mergeRequestsIllustrationPath = 'illustrations/merge_requests.svg';
  let wrapper;
  let router;

  const buildRouter = () => {
    router = {
      push: jest.fn(),
    };
  };

  const buildWrapper = (data = {}, appData = {}) => {
    wrapper = shallowMount(Success, {
      mocks: {
        $router: router,
      },
      stubs: {
        GlButton,
        GlEmptyState,
        GlLoadingIcon,
      },
      propsData: {
        mergeRequestsIllustrationPath,
      },
      data() {
        return {
          savedContentMeta,
          appData: {
            returnUrl,
            sourcePath,
            hasSubmittedChanges: true,
            ...appData,
          },
          ...data,
        };
      },
    });
  };

  const findReturnUrlButton = () => wrapper.find(GlButton);
  const findEmptyState = () => wrapper.find(GlEmptyState);
  const findLoadingIcon = () => wrapper.find(GlLoadingIcon);

  beforeEach(() => {
    buildRouter();
  });

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  describe('when savedContentMeta is valid', () => {
    it('renders empty state with a link to the created merge request', () => {
      buildWrapper();

      expect(findEmptyState().exists()).toBe(true);
      expect(findEmptyState().props()).toMatchObject({
        primaryButtonText: 'View merge request',
        primaryButtonLink: savedContentMeta.mergeRequest.url,
        title: 'Your merge request has been created',
        svgPath: mergeRequestsIllustrationPath,
        svgHeight: 146,
      });
    });

    it('displays merge request instructions in the empty state', () => {
      buildWrapper();

      expect(findEmptyState().text()).toContain(
        'To see your changes live you will need to do the following things:',
      );
      expect(findEmptyState().text()).toContain('1. Add a clear title to describe the change.');
      expect(findEmptyState().text()).toContain(
        '2. Add a description to explain why the change is being made.',
      );
      expect(findEmptyState().text()).toContain(
        '3. Assign a person to review and accept the merge request.',
      );
    });

    it('displays return to site button', () => {
      buildWrapper();

      expect(findReturnUrlButton().text()).toBe('Return to site');
      expect(findReturnUrlButton().attributes().href).toBe(returnUrl);
    });

    it('displays source path', () => {
      buildWrapper();

      expect(wrapper.text()).toContain(`Update ${sourcePath} file`);
    });
  });

  describe('when savedContentMeta is invalid', () => {
    it('renders empty state with a loader', () => {
      buildWrapper({ savedContentMeta: null });

      expect(findEmptyState().exists()).toBe(true);
      expect(findEmptyState().props()).toMatchObject({
        title: 'Creating your merge request',
        svgPath: mergeRequestsIllustrationPath,
      });
      expect(findLoadingIcon().exists()).toBe(true);
    });

    it('displays helper info in the empty state', () => {
      buildWrapper({ savedContentMeta: null });

      expect(findEmptyState().text()).toContain(
        'You can set an assignee to get your changes reviewed and deployed once your merge request is created',
      );
      expect(findEmptyState().text()).toContain(
        'A link to view the merge request will appear once ready',
      );
    });

    it('redirects to the HOME route when content has not been submitted', () => {
      buildWrapper({ savedContentMeta: null }, { hasSubmittedChanges: false });

      expect(router.push).toHaveBeenCalledWith(HOME_ROUTE);
    });
  });
});
