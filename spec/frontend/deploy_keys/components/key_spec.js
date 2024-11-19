import VueApollo from 'vue-apollo';
import Vue, { nextTick } from 'vue';
import { mount } from '@vue/test-utils';
import enabledKeys from 'test_fixtures/deploy_keys/enabled_keys.json';
import availablePublicKeys from 'test_fixtures/deploy_keys/available_public_keys.json';
import { createAlert } from '~/alert';
import { mapDeployKey } from '~/deploy_keys/graphql/resolvers';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { createMockDirective, getBinding } from 'helpers/vue_mock_directive';
import key from '~/deploy_keys/components/key.vue';
import ActionBtn from '~/deploy_keys/components/action_btn.vue';
import { getTimeago, localeDateFormat } from '~/lib/utils/datetime_utility';

jest.mock('~/alert');

Vue.use(VueApollo);

describe('Deploy keys key', () => {
  let wrapper;
  let currentScopeMock;

  const findTextAndTrim = (selector) => wrapper.find(selector).text().trim();

  const createComponent = async (propsData) => {
    const resolvers = {
      Query: {
        currentScope: currentScopeMock,
      },
    };

    const apolloProvider = createMockApollo([], resolvers);
    wrapper = mount(key, {
      propsData: {
        endpoint: 'https://test.host/dummy/endpoint',
        ...propsData,
      },
      apolloProvider,
      directives: {
        GlTooltip: createMockDirective('gl-tooltip'),
      },
    });
    await nextTick();
  };

  beforeEach(() => {
    currentScopeMock = jest.fn();
  });

  describe('enabled key', () => {
    const deployKey = mapDeployKey(enabledKeys.keys[0]);

    beforeEach(() => {
      currentScopeMock.mockReturnValue('enabledKeys');
    });

    it('renders the keys title', async () => {
      await createComponent({ deployKey });

      expect(findTextAndTrim('.title')).toContain(deployKey.title);
    });

    it('renders human friendly formatted created date', async () => {
      await createComponent({ deployKey });

      expect(findTextAndTrim('.key-created-at')).toBe(
        `${getTimeago().format(deployKey.createdAt)}`,
      );
    });

    it('renders human friendly expiration date', async () => {
      const expiresAt = new Date();
      await createComponent({
        deployKey: { ...deployKey, expiresAt },
      });

      expect(findTextAndTrim('.key-expires-at')).toBe(`${getTimeago().format(expiresAt)}`);
    });
    it('shows tooltip for expiration date', async () => {
      const expiresAt = new Date();
      await createComponent({
        deployKey: { ...deployKey, expiresAt },
      });

      const expiryComponent = wrapper.find('[data-testid="expires-at-tooltip"]');
      const tooltip = getBinding(expiryComponent.element, 'gl-tooltip');
      expect(tooltip).toBeDefined();
      expect(expiryComponent.attributes('title')).toBe(
        `${localeDateFormat.asDateTimeFull.format(expiresAt)}`,
      );
    });
    it('renders never when no expiration date', async () => {
      await createComponent({
        deployKey: { ...deployKey, expiresAt: null },
      });

      expect(wrapper.find('[data-testid="expires-never"]').exists()).toBe(true);
    });

    it('shows pencil button for editing', async () => {
      await createComponent({ deployKey });

      expect(wrapper.find('.btn [data-testid="pencil-icon"]').exists()).toBe(true);
    });

    it('shows disable button when the project is not deletable', async () => {
      await createComponent({ deployKey });
      await waitForPromises();

      expect(wrapper.find('.btn [data-testid="cancel-icon"]').exists()).toBe(true);
    });

    it('shows remove button when the project is deletable', async () => {
      await createComponent({
        deployKey: { ...deployKey, destroyedWhenOrphaned: true, almostOrphaned: true },
      });
      await waitForPromises();
      expect(wrapper.find('.btn [data-testid="remove-icon"]').exists()).toBe(true);
    });
  });

  describe('deploy key labels', () => {
    const deployKey = mapDeployKey(enabledKeys.keys[0]);
    const deployKeysProjects = [...deployKey.deployKeysProjects];
    it('shows write access title when key has write access', async () => {
      deployKeysProjects[0] = { ...deployKeysProjects[0], canPush: true };
      await createComponent({ deployKey: { ...deployKey, deployKeysProjects } });

      expect(wrapper.find('.deploy-project-label').attributes('title')).toBe(
        'Grant write permissions to this key',
      );
    });

    it('does not show write access title when key has write access', async () => {
      deployKeysProjects[0] = { ...deployKeysProjects[0], canPush: false };
      await createComponent({ deployKey: { ...deployKey, deployKeysProjects } });

      expect(wrapper.find('.deploy-project-label').attributes('title')).toBe('Read access only');
    });

    it('shows expandable button if more than two projects', async () => {
      await createComponent({ deployKey });
      const labels = wrapper.findAll('.deploy-project-label');

      expect(labels.length).toBe(2);
      expect(labels.at(1).text()).toContain('others');
      expect(labels.at(1).attributes('title')).toContain('Expand');
    });

    it('expands all project labels after click', async () => {
      await createComponent({ deployKey });
      const { length } = deployKey.deployKeysProjects;
      wrapper.findAll('.deploy-project-label').at(1).trigger('click');

      await nextTick();
      const labels = wrapper.findAll('.deploy-project-label');

      expect(labels).toHaveLength(length);
      expect(labels.at(1).text()).not.toContain(`+${length} others`);
      expect(labels.at(1).attributes('title')).not.toContain('Expand');
    });

    it('shows two projects', async () => {
      await createComponent({
        deployKey: { ...deployKey, deployKeysProjects: [...deployKeysProjects].slice(0, 2) },
      });

      const labels = wrapper.findAll('.deploy-project-label');

      expect(labels.length).toBe(2);
      expect(labels.at(1).text()).toContain(deployKey.deployKeysProjects[1].project.fullName);
    });
  });

  describe('public keys', () => {
    const deployKey = mapDeployKey(availablePublicKeys.keys[0]);

    it('renders deploy keys without any enabled projects', async () => {
      await createComponent({ deployKey: { ...deployKey, deployKeysProjects: [] } });

      expect(findTextAndTrim('.deploy-project-list')).toBe('None');
    });

    it('shows enable button', async () => {
      await createComponent({ deployKey });
      expect(findTextAndTrim('.btn')).toBe('Enable');
    });

    it('shows an error on enable failure', async () => {
      await createComponent({ deployKey });

      const error = new Error('oops!');
      wrapper.findComponent(ActionBtn).vm.$emit('error', error);

      await nextTick();

      expect(createAlert).toHaveBeenCalledWith({
        message: 'Error enabling deploy key',
        captureError: true,
        error,
      });
    });

    it('shows pencil button for editing', async () => {
      await createComponent({ deployKey });
      expect(wrapper.find('.btn [data-testid="pencil-icon"]').exists()).toBe(true);
    });

    it('shows disable button when key is enabled', async () => {
      currentScopeMock.mockReturnValue('enabledKeys');
      await createComponent({ deployKey });
      await waitForPromises();

      expect(wrapper.find('.btn [data-testid="cancel-icon"]').exists()).toBe(true);
    });
  });
});
