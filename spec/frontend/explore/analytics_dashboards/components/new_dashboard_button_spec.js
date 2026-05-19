import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { GlButton, GlModal, GlAlert } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import NewDashboardButton from '~/explore/analytics_dashboards/components/new_dashboard_button.vue';
import createCustomDashboardMutation from '~/explore/analytics_dashboards/graphql/create_custom_dashboard.mutation.graphql';
import * as urlUtility from '~/lib/utils/url_utility';

Vue.use(VueApollo);

jest.mock('~/lib/utils/url_utility', () => ({
  ...jest.requireActual('~/lib/utils/url_utility'),
  visitUrl: jest.fn(),
}));

describe('NewDashboardButton', () => {
  let wrapper;
  let mockApollo;

  const mockDashboardId = '123';
  const mockGraphQLDashboardId = `gid://gitlab/Analytics::CustomDashboard/${mockDashboardId}`;

  const mockApolloProvider = (customResolver) =>
    createMockApollo([
      [
        createCustomDashboardMutation,
        customResolver ||
          jest.fn().mockResolvedValue({
            data: {
              createCustomDashboard: {
                dashboard: {
                  id: mockGraphQLDashboardId,
                },
                errors: [],
              },
            },
          }),
      ],
    ]);

  const createComponent = (response) => {
    mockApollo = mockApolloProvider(response);
    jest.spyOn(mockApollo.defaultClient, 'mutate');

    wrapper = shallowMountExtended(NewDashboardButton, {
      apolloProvider: mockApollo,
      mocks: {
        $router: {
          options: {
            base: '/explore/analytics_dashboards/',
          },
        },
      },
    });
  };

  const findButton = () => wrapper.findComponent(GlButton);
  const findModal = () => wrapper.findComponent(GlModal);
  const findTitleInput = () => wrapper.findByTestId('dashboard-title-input');
  const findDescriptionTextarea = () => wrapper.findByTestId('dashboard-description-textarea');
  const findErrorAlert = () => wrapper.findComponent(GlAlert);

  it('renders the New dashboard button', () => {
    createComponent();

    expect(findButton().exists()).toBe(true);
    expect(findButton().text()).toBe('New dashboard');
  });

  it('opens the New dashboard modal when button is clicked', async () => {
    createComponent();

    expect(findModal().props('visible')).toBe(false);

    await findButton().vm.$emit('click');

    expect(findModal().props('visible')).toBe(true);
  });

  describe('modal content', () => {
    beforeEach(() => {
      createComponent();
      return findButton().vm.$emit('click');
    });

    it('renders a Dashboard title input field', () => {
      expect(findTitleInput().exists()).toBe(true);
    });

    it('renders a Dashboard description text area', () => {
      expect(findDescriptionTextarea().exists()).toBe(true);
    });

    it('closes the modal when the cancel action is pressed', async () => {
      await findModal().vm.$emit('canceled');

      expect(findModal().props('visible')).toBe(false);
    });

    it('does not initially show the error alert', () => {
      expect(findErrorAlert().exists()).toBe(false);
    });
  });

  describe('form loading', () => {
    beforeEach(async () => {
      createComponent();
      await findButton().vm.$emit('click');

      findTitleInput().vm.$emit('input', 'test');
      findModal().vm.$emit('primary', { preventDefault: jest.fn() });
    });

    it('disables the title input', () => {
      expect(findTitleInput().props('disabled')).toBe(true);
    });

    it('disables the description text area', () => {
      expect(findDescriptionTextarea().attributes('disabled')).toBeDefined();
    });

    it('disables the cancel action', () => {
      expect(findModal().props('actionCancel').attributes.disabled).toBe(true);
    });

    it('puts the Next button into a loading state', () => {
      expect(findModal().props('actionPrimary').attributes.loading).toBe(true);
    });
  });

  describe('title error', () => {
    beforeEach(async () => {
      createComponent();
      await findButton().vm.$emit('click');

      findModal().vm.$emit('primary', { preventDefault: jest.fn() });
    });

    it('does not send a create request', () => {
      expect(mockApollo.defaultClient.mutate).not.toHaveBeenCalled();
    });

    it('shows the title required error alert', () => {
      expect(findErrorAlert().exists()).toBe(true);
      expect(findErrorAlert().text()).toContain('Dashboard title is required');
    });
  });

  describe('request error', () => {
    const error = 'Something went wrong';

    beforeEach(async () => {
      createComponent(
        jest.fn().mockResolvedValue({
          data: {
            createCustomDashboard: {
              dashboard: null,
              errors: [error],
            },
          },
        }),
      );

      await findButton().vm.$emit('click');
      findTitleInput().vm.$emit('input', 'Test Dashboard');

      findModal().vm.$emit('primary', { preventDefault: jest.fn() });
      await waitForPromises();
    });

    it('shows the first error in the error alert', () => {
      expect(findErrorAlert().exists()).toBe(true);
      expect(findErrorAlert().text()).toContain(error);
    });

    it('stops the loading state', () => {
      expect(findModal().props('actionPrimary').attributes.loading).toBe(false);
    });
  });

  describe('server error', () => {
    beforeEach(async () => {
      createComponent(jest.fn().mockRejectedValue(new Error('Network error')));

      await findButton().vm.$emit('click');
      findTitleInput().vm.$emit('input', 'Test Dashboard');

      findModal().vm.$emit('primary', { preventDefault: jest.fn() });
      await waitForPromises();
    });

    it('shows the generic error alert', () => {
      expect(findErrorAlert().exists()).toBe(true);
      expect(findErrorAlert().text()).toContain('Failed to create dashboard');
    });

    it('stops the loading state', () => {
      expect(findModal().props('actionPrimary').attributes.loading).toBe(false);
    });
  });

  describe('dashboard created', () => {
    const name = 'Test dashboard';
    const description = 'Test description';

    beforeEach(async () => {
      createComponent();

      await findButton().vm.$emit('click');
      findTitleInput().vm.$emit('input', name);
      findDescriptionTextarea().vm.$emit('input', description);

      findModal().vm.$emit('primary', { preventDefault: jest.fn() });
      await waitForPromises();
    });

    it('sends the create dashboard mutation with the correct payload', () => {
      expect(mockApollo.defaultClient.mutate).toHaveBeenCalledWith({
        mutation: createCustomDashboardMutation,
        variables: {
          input: {
            name,
            description,
            config: {
              title: name,
              description,
              panels: [],
            },
          },
        },
      });
    });

    it('redirects to the new dashboard details page', () => {
      expect(urlUtility.visitUrl).toHaveBeenCalledWith('/explore/analytics_dashboards/123');
    });
  });

  describe('opening the modal', () => {
    beforeEach(async () => {
      createComponent();
      await findButton().vm.$emit('click');
    });

    it('clears the title input', async () => {
      findTitleInput().vm.$emit('input', 'Previous Title');

      await findModal().vm.$emit('canceled');
      await findButton().vm.$emit('click');

      expect(findTitleInput().props('value')).toBe('');
    });

    it('clears the description text area', async () => {
      findDescriptionTextarea().vm.$emit('input', 'Previous Description');

      await findModal().vm.$emit('canceled');
      await findButton().vm.$emit('click');

      expect(findDescriptionTextarea().props('value')).toBe('');
    });

    it('clears the error alert', async () => {
      await findModal().vm.$emit('primary', { preventDefault: jest.fn() });
      expect(findErrorAlert().exists()).toBe(true);

      await findModal().vm.$emit('canceled');
      await findButton().vm.$emit('click');

      expect(findErrorAlert().exists()).toBe(false);
    });
  });
});
