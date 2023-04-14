import { nextTick } from 'vue';
import { GlFormCheckbox, GlFormRadioGroup } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import PushEvents from '~/webhooks/components/push_events.vue';

describe('Webhook push events form editor component', () => {
  let wrapper;

  const findPushEventsCheckBox = (w = wrapper) => w.findComponent(GlFormCheckbox);
  const findPushEventsIndicator = (w = wrapper) => w.find('input[name="hook[push_events]"]');
  const findPushEventRulesGroup = (w = wrapper) => w.findComponent(GlFormRadioGroup);
  const getPushEventsRuleValue = (w = wrapper) => findPushEventRulesGroup(w).vm.$attrs.checked;
  const findWildcardRuleInput = (w = wrapper) => w.findByTestId('webhook_branch_filter_field');
  const findRegexRuleInput = (w = wrapper) => w.findByTestId('webhook_branch_filter_field');

  const createComponent = (provides) =>
    shallowMountExtended(PushEvents, {
      provide: {
        isNewHook: true,
        pushEvents: false,
        strategy: 'wildcard',
        pushEventsBranchFilter: '',
        ...provides,
      },
    });

  describe('Renders push events checkbox', () => {
    it('when it is a new hook', async () => {
      wrapper = createComponent({
        isNewHook: true,
      });
      await nextTick();

      const checkbox = findPushEventsCheckBox();
      expect(checkbox.exists()).toBe(true);
      expect(findPushEventRulesGroup().exists()).toBe(false);
      expect(findPushEventsIndicator().attributes('value')).toBe('false');
    });

    it('when it is not a new hook and push events is enabled', async () => {
      wrapper = createComponent({
        isNewHook: false,
        pushEvents: true,
      });
      await nextTick();

      expect(findPushEventsCheckBox().exists()).toBe(true);
      expect(findPushEventRulesGroup().exists()).toBe(true);
      expect(findPushEventsIndicator().attributes('value')).toBe('true');
    });
  });

  describe('Different push events rules', () => {
    describe('when editing new hook', () => {
      beforeEach(async () => {
        wrapper = createComponent({
          isNewHook: true,
        });
        await nextTick();
        await findPushEventsCheckBox().vm.$emit('input', true);
        await nextTick();
      });

      it('all_branches should be selected by default', () => {
        expect(findPushEventRulesGroup().element).toMatchSnapshot();
      });

      it('should be able to set wildcard rule', async () => {
        expect(getPushEventsRuleValue()).toBe('all_branches');
        expect(findWildcardRuleInput().exists()).toBe(false);
        expect(findRegexRuleInput().exists()).toBe(false);

        await findPushEventRulesGroup(wrapper).vm.$emit('input', 'wildcard');
        expect(findWildcardRuleInput().exists()).toBe(true);
        expect(findPushEventRulesGroup().element).toMatchSnapshot();

        const testVal = 'test-val';
        findWildcardRuleInput().vm.$emit('input', testVal);
        await nextTick();
        expect(findWildcardRuleInput().attributes('value')).toBe(testVal);
      });

      it('should be able to set regex rule', async () => {
        expect(getPushEventsRuleValue()).toBe('all_branches');
        expect(findRegexRuleInput().exists()).toBe(false);
        expect(findWildcardRuleInput().exists()).toBe(false);

        await findPushEventRulesGroup(wrapper).vm.$emit('input', 'regex');
        expect(findRegexRuleInput().exists()).toBe(true);
        expect(findPushEventRulesGroup().element).toMatchSnapshot();

        const testVal = 'test-val';
        findRegexRuleInput().vm.$emit('input', testVal);
        await nextTick();
        expect(findRegexRuleInput().attributes('value')).toBe(testVal);
      });
    });

    describe('when editing existing hook', () => {
      it.each(['all_branches', 'wildcard', 'regex'])(
        'with "%s" strategy selected',
        async (strategy) => {
          wrapper = createComponent({
            isNewHook: false,
            pushEvents: true,
            pushEventsBranchFilter: 'foo',
            strategy,
          });
          await nextTick();

          expect(findPushEventsIndicator().attributes('value')).toBe('true');
          expect(findPushEventRulesGroup().element).toMatchSnapshot();
        },
      );
    });
  });
});
