import { nextTick } from 'vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import WebhookFormApp from '~/webhooks/components/webhook_form_app.vue';
import FormUrlApp from '~/webhooks/components/form_url_app.vue';
import FormCustomHeaders from '~/webhooks/components/form_custom_headers.vue';
import WebhookFormTriggerList from '~/webhooks/components/webhook_form_trigger_list.vue';

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

  const createComponent = ({ props = {} } = {}) => {
    wrapper = shallowMountExtended(WebhookFormApp, {
      propsData: {
        initialTriggers: defaultInitialTriggers,
        isNewHook: false,
        hasGroup: false,
        ...props,
      },
    });
  };

  const findNameInput = () => wrapper.findByTestId('webhook-name');
  const findDescriptionInput = () => wrapper.findByTestId('webhook-description');
  const findSecretTokenInput = () => wrapper.findByTestId('webhook-secret-token');
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
      });
    });

    it('passes initialUrl and initialUrlVariables to FormUrlApp', () => {
      const initialUrl = 'https://webhook.site';
      const initialUrlVariables = [{ key: 'test', value: 'value' }];

      createComponent({
        props: {
          initialUrl,
          initialUrlVariables,
        },
      });

      expect(findFormUrlApp().props()).toMatchObject({
        initialUrl,
        initialUrlVariables,
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
