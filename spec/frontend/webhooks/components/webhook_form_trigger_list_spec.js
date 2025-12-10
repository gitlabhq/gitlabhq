import { nextTick } from 'vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';

import WebhookFormTriggerList from '~/webhooks/components/webhook_form_trigger_list.vue';
import WebhookFormTriggerItem from '~/webhooks/components/webhook_form_trigger_item.vue';
import PushEvents from '~/webhooks/components/push_events.vue';
import { TRIGGER_CONFIG } from '~/webhooks/constants';

describe('WebhookFormTriggerList', () => {
  let wrapper;

  const defaultInitialTriggers = {
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

  const createComponent = ({ props } = {}) => {
    wrapper = shallowMountExtended(WebhookFormTriggerList, {
      propsData: {
        initialTriggers: defaultInitialTriggers,
        hasGroup: false,
        ...props,
      },
    });
  };

  const findAllTriggerItems = () => wrapper.findAllComponents(WebhookFormTriggerItem);
  const findTriggerByTestId = (key) => wrapper.findByTestId(key);
  const findPushEvents = () => wrapper.findComponent(PushEvents);

  const nthTriggerItem = (n) => {
    return findAllTriggerItems().at(n);
  };
  const nthConfig = (n, configArray) => {
    return configArray[n];
  };

  describe('by default', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders PushEvents', () => {
      expect(findPushEvents().isVisible()).toBe(true);
      expect(findPushEvents().props()).toMatchObject({
        pushEvents: false,
        strategy: '',
        isNewHook: false,
        pushEventsBranchFilter: '',
      });
    });

    it('renders WebhookFormTriggerItem for each trigger', () => {
      TRIGGER_CONFIG.forEach((config) => {
        expect(findTriggerByTestId(config.key).exists()).toBe(true);
      });
    });

    it('passes correct props to each WebhookFormTriggerItem', () => {
      const secondTrigger = nthTriggerItem(1);
      const secondConfig = nthConfig(1, TRIGGER_CONFIG);
      const tenthTrigger = nthTriggerItem(9);
      const tenthConfig = nthConfig(9, TRIGGER_CONFIG);

      expect(secondTrigger.props()).toMatchObject({
        inputName: secondConfig.inputName,
        triggerName: secondConfig.key,
        label: secondConfig.label,
        helpText: secondConfig.helpText,
      });

      expect(tenthTrigger.props()).toMatchObject({
        inputName: tenthConfig.inputName,
        triggerName: tenthConfig.key,
        label: tenthConfig.label,
        helpText: tenthConfig.helpText,
      });
    });
  });

  describe('data binding', () => {
    const customTriggers = {
      ...defaultInitialTriggers,
      tagPushEvents: true,
      issuesEvents: true,
    };

    beforeEach(() => {
      createComponent({ props: { initialTriggers: customTriggers } });
    });

    it('passes correct values to trigger items based on initial state', () => {
      expect(findTriggerByTestId('pipelineEvents').props('value')).toBe(false);

      expect(findTriggerByTestId('tagPushEvents').props('value')).toBe(true);
      expect(findTriggerByTestId('issuesEvents').props('value')).toBe(true);
    });

    it('updates internal triggers data when trigger item emits input event', async () => {
      const featureFlagTrigger = findTriggerByTestId('featureFlagEvents');
      expect(featureFlagTrigger.props('value')).toBe(false);

      await featureFlagTrigger.vm.$emit('input', true);
      await nextTick();
      expect(featureFlagTrigger.props('value')).toBe(true);

      await featureFlagTrigger.vm.$emit('input', false);
      await nextTick();
      expect(featureFlagTrigger.props('value')).toBe(false);
    });

    it('maintains reactivity when multiple triggers are toggled', async () => {
      const tagPushTrigger = findTriggerByTestId('tagPushEvents');
      const issuesTrigger = findTriggerByTestId('issuesEvents');

      const pipelineTrigger = findTriggerByTestId('pipelineEvents');

      tagPushTrigger.vm.$emit('input', false);
      await nextTick();

      issuesTrigger.vm.$emit('input', false);
      await nextTick();

      pipelineTrigger.vm.$emit('input', true);
      await nextTick();

      expect(tagPushTrigger.props('value')).toBe(false);
      expect(wrapper.vm.triggers.issuesEvents).toBe(false);
      expect(wrapper.vm.triggers.pipelineEvents).toBe(true);
    });
  });
});
