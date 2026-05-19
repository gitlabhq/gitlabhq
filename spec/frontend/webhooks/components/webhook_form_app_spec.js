import { nextTick } from 'vue';
import { GlFormGroup } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import WebhookFormApp from '~/webhooks/components/webhook_form_app.vue';
import FormUrlApp from '~/webhooks/components/form_url_app.vue';
import FormCustomHeaders from '~/webhooks/components/form_custom_headers.vue';
import WebhookFormTriggerList from '~/webhooks/components/webhook_form_trigger_list.vue';
import WebhookTokenInput from '~/webhooks/components/webhook_token_input.vue';

describe('WebhookFormApp', () => {
  let wrapper;

  const defaultInitialTriggers = {
    pushEvents: false,
    pushEventsBranchFilter: '',
    branchFilterStrategy: '',
    tagPushEvents: false,
    noteEvents: false,
    confidentialNoteEvents: false,
    issuesEvents: false,
    confidentialIssuesEvents: false,
    memberEvents: false,
    projectEvents: false,
    subgroupEvents: false,
    mergeRequestsEvents: false,
    jobEvents: false,
    pipelineEvents: false,
    wikiPageEvents: false,
    deploymentEvents: false,
    featureFlagEvents: false,
    releasesEvents: false,
    milestoneEvents: false,
    emojiEvents: false,
    resourceAccessTokenEvents: false,
    vulnerabilityEvents: false,
  };

  const createComponent = ({ props = {}, glFeatures = {} } = {}) => {
    wrapper = shallowMountExtended(WebhookFormApp, {
      propsData: {
        initialTriggers: defaultInitialTriggers,
        isNewHook: false,
        hasGroup: false,
        ...props,
      },
      provide: { glFeatures },
    });
  };

  const findNameInput = () => wrapper.findByTestId('webhook-name');
  const findDescriptionInput = () => wrapper.findByTestId('webhook-description');
  const findSecretTokenInput = () => wrapper.findByTestId('webhook-secret-token');
  const findWebhookTokenInput = () => wrapper.findComponent(WebhookTokenInput);
  const findFormUrlApp = () => wrapper.findComponent(FormUrlApp);
  const findFormCustomHeaders = () => wrapper.findComponent(FormCustomHeaders);
  const findWebhookFormTriggerList = () => wrapper.findComponent(WebhookFormTriggerList);

  beforeEach(() => {
    createComponent();
  });

  describe('name input', () => {
    it('renders name input', () => {
      expect(findNameInput().props('name')).toBe('hook[name]');
      expect(findNameInput().props('value')).toBe('');
    });

    it('uses initialName as initial value', () => {
      const initialName = 'Test Name';

      createComponent({
        props: {
          initialName,
        },
      });

      expect(findNameInput().props('value')).toBe(initialName);
    });
  });

  describe('description input', () => {
    it('renders description input', () => {
      expect(findDescriptionInput().attributes('name')).toBe('hook[description]');
      expect(findDescriptionInput().props('value')).toBe('');
    });

    it('uses initialDescription as initial value', async () => {
      const initialDescription = 'Test Description';

      createComponent({
        props: {
          initialDescription,
        },
      });
      await nextTick();

      expect(findDescriptionInput().props('value')).toBe(initialDescription);
    });
  });

  describe('secret token input', () => {
    it('renders secret token input', () => {
      expect(findSecretTokenInput().attributes('name')).toBe('hook[token]');
      expect(findSecretTokenInput().props('value')).toBe('');
    });

    it('uses initialSecretToken as initial value', () => {
      const initialSecretToken = '************';

      createComponent({
        props: {
          initialSecretToken,
        },
      });

      expect(findSecretTokenInput().props('value')).toBe(initialSecretToken);
    });
  });

  describe('FormUrlApp component', () => {
    it('renders FormUrlApp', () => {
      expect(findFormUrlApp().props()).toMatchObject({
        initialUrl: null,
        initialUrlVariables: [],
        initialSecretToken: '',
      });
    });

    it('passes initialUrl, initialUrlVariables, and initialSecretToken to FormUrlApp', () => {
      const initialUrl = 'https://webhook.site';
      const initialUrlVariables = [{ key: 'test', value: 'value' }];
      const initialSecretToken = '************';

      createComponent({
        props: {
          initialUrl,
          initialUrlVariables,
          initialSecretToken,
        },
      });

      expect(findFormUrlApp().props()).toMatchObject({
        initialUrl,
        initialUrlVariables,
        initialSecretToken,
      });
    });
  });

  describe('FormCustomHeaders component', () => {
    it('renders FormCustomHeaders', () => {
      expect(findFormCustomHeaders().props()).toMatchObject({
        initialCustomHeaders: [],
      });
    });

    it('passes initialCustomHeaders to FormCustomHeaders', () => {
      const initialCustomHeaders = [{ key: 'Authorization', value: 'Bearer token' }];

      createComponent({
        props: {
          initialCustomHeaders,
        },
      });

      expect(findFormCustomHeaders().props()).toMatchObject({
        initialCustomHeaders,
      });
    });
  });

  describe('signing token', () => {
    const findSecretTokenFormGroup = () =>
      wrapper
        .findAllComponents(GlFormGroup)
        .filter((c) => c.attributes('label-for') === 'webhook-secret-token')
        .at(0);
    const findSecretTokenAlert = () => wrapper.findByTestId('secret-token-not-recommended-alert');

    describe('when webhookSigningToken feature flag is disabled (default)', () => {
      it('does not render WebhookTokenInput', () => {
        expect(findWebhookTokenInput().exists()).toBe(false);
      });

      it('renders the secret token label without "(optional)"', () => {
        expect(findSecretTokenFormGroup().attributes('label')).toBe('Secret token');
      });
    });

    describe('when webhookSigningToken feature flag is enabled', () => {
      it('renders WebhookTokenInput', () => {
        createComponent({ glFeatures: { webhookSigningToken: true } });

        expect(findWebhookTokenInput().exists()).toBe(true);
      });

      it('passes hasSigningToken as hasExistingToken to WebhookTokenInput', () => {
        createComponent({
          glFeatures: { webhookSigningToken: true },
          props: { hasSigningToken: true },
        });

        expect(findWebhookTokenInput().props('hasExistingToken')).toBe(true);
      });

      it('passes signingTokenDocsPath as docsPath to WebhookTokenInput', () => {
        createComponent({
          glFeatures: { webhookSigningToken: true },
          props: { signingTokenDocsPath: '/help/webhooks' },
        });

        expect(findWebhookTokenInput().props('docsPath')).toBe('/help/webhooks');
      });

      it('renders WebhookTokenInput with hook[signing_token] inputName prop', () => {
        createComponent({ glFeatures: { webhookSigningToken: true } });

        expect(findWebhookTokenInput().props('inputName')).toBe('hook[signing_token]');
      });

      it('renders the secret token label with "(not recommended)"', () => {
        createComponent({ glFeatures: { webhookSigningToken: true } });

        expect(findSecretTokenFormGroup().attributes('label')).toBe(
          'Secret token (not recommended)',
        );
      });

      it('does not show the secret token alert when no initial secret token', () => {
        createComponent({ glFeatures: { webhookSigningToken: true } });

        expect(findSecretTokenAlert().exists()).toBe(false);
      });

      it('shows the secret token not-recommended alert when initial secret token exists', () => {
        createComponent({
          glFeatures: { webhookSigningToken: true },
          props: { initialSecretToken: '************' },
        });

        expect(findSecretTokenAlert().exists()).toBe(true);
      });
    });
  });

  describe('trigger list component', () => {
    it('is passed the correct data', () => {
      createComponent({
        props: {
          hasGroup: true,
        },
      });

      expect(findWebhookFormTriggerList().props()).toMatchObject({
        initialTriggers: defaultInitialTriggers,
        hasGroup: true,
      });
    });
  });
});
