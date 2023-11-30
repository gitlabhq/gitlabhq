import { GlFormCheckbox } from '@gitlab/ui';
import Vue, { nextTick } from 'vue';
// eslint-disable-next-line no-restricted-imports
import Vuex from 'vuex';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import JiraTriggerFields from '~/integrations/edit/components/jira_trigger_fields.vue';

Vue.use(Vuex);

describe('JiraTriggerFields', () => {
  let wrapper;
  let store;

  const defaultProps = {
    initialTriggerCommit: false,
    initialTriggerMergeRequest: false,
    initialEnableComments: false,
  };

  const createComponent = (props, isInheriting = false) => {
    store = new Vuex.Store({
      getters: {
        isInheriting: () => isInheriting,
      },
    });

    wrapper = mountExtended(JiraTriggerFields, {
      propsData: { ...defaultProps, ...props },
      store,
    });
  };

  const findCommentSettings = () => wrapper.findByTestId('comment-settings');
  const findCommentDetail = () => wrapper.findByTestId('comment-detail');
  const findCommentSettingsCheckbox = () => findCommentSettings().findComponent(GlFormCheckbox);
  const findIssueTransitionEnabled = () =>
    wrapper.find('[data-testid="issue-transition-enabled"] input[type="checkbox"]');
  const findIssueTransitionMode = () => wrapper.findByTestId('issue-transition-mode');
  const findIssueTransitionModeRadios = () =>
    findIssueTransitionMode().findAll('input[type="radio"]');
  const findIssueTransitionIdsField = () =>
    wrapper.find('input[type="text"][name="service[jira_issue_transition_id]"]');

  describe('template', () => {
    describe('initialTriggerCommit and initialTriggerMergeRequest are false', () => {
      it('does not show trigger settings', () => {
        createComponent();

        expect(findCommentSettings().isVisible()).toBe(false);
        expect(findCommentDetail().isVisible()).toBe(false);
        expect(findIssueTransitionEnabled().exists()).toBe(false);
        expect(findIssueTransitionMode().exists()).toBe(false);
      });
    });

    describe('initialTriggerCommit is true', () => {
      beforeEach(() => {
        createComponent({
          initialTriggerCommit: true,
        });
      });

      it('shows trigger settings', () => {
        expect(findCommentSettings().isVisible()).toBe(true);
        expect(findCommentDetail().isVisible()).toBe(false);
        expect(findIssueTransitionEnabled().isVisible()).toBe(true);
        expect(findIssueTransitionMode().exists()).toBe(false);
      });

      // As per https://vuejs.org/v2/guide/forms.html#Checkbox-1,
      // browsers don't include unchecked boxes in form submissions.
      it('includes comment settings as false even if unchecked', () => {
        expect(
          findCommentSettings().find('input[name="service[comment_on_event_enabled]"]').exists(),
        ).toBe(true);
      });

      describe('on enable comments', () => {
        it('shows comment detail', async () => {
          findCommentSettingsCheckbox().vm.$emit('input', true);

          await nextTick();
          expect(findCommentDetail().isVisible()).toBe(true);
        });
      });
    });

    describe('initialTriggerMergeRequest is true', () => {
      it('shows trigger settings', () => {
        createComponent({
          initialTriggerMergeRequest: true,
        });

        expect(findCommentSettings().isVisible()).toBe(true);
        expect(findCommentDetail().isVisible()).toBe(false);
        expect(findIssueTransitionEnabled().isVisible()).toBe(true);
        expect(findIssueTransitionMode().exists()).toBe(false);
      });
    });

    describe('initialTriggerCommit is true, initialEnableComments is true', () => {
      it('shows comment settings and comment detail', () => {
        createComponent({
          initialTriggerCommit: true,
          initialEnableComments: true,
        });

        expect(findCommentSettings().isVisible()).toBe(true);
        expect(findCommentDetail().isVisible()).toBe(true);
      });
    });

    describe('initialJiraIssueTransitionAutomatic is false, initialJiraIssueTransitionId is not set', () => {
      it('selects automatic transitions when enabling transitions', async () => {
        createComponent({
          initialTriggerCommit: true,
          initialEnableComments: true,
        });

        const checkbox = findIssueTransitionEnabled();
        expect(checkbox.element.checked).toBe(false);
        await checkbox.setChecked(true);

        const [radio1, radio2] = findIssueTransitionModeRadios().wrappers;
        expect(radio1.element.checked).toBe(true);
        expect(radio2.element.checked).toBe(false);
      });
    });

    describe('initialJiraIssueTransitionAutomatic is true', () => {
      it('uses automatic transitions', () => {
        createComponent({
          initialTriggerCommit: true,
          initialJiraIssueTransitionAutomatic: true,
        });

        expect(findIssueTransitionEnabled().element.checked).toBe(true);

        const [radio1, radio2] = findIssueTransitionModeRadios().wrappers;
        expect(radio1.element.checked).toBe(true);
        expect(radio2.element.checked).toBe(false);

        expect(findIssueTransitionIdsField().exists()).toBe(false);
      });
    });

    describe('initialJiraIssueTransitionId is set', () => {
      it('uses custom transitions', () => {
        createComponent({
          initialTriggerCommit: true,
          initialJiraIssueTransitionId: '1, 2, 3',
        });

        expect(findIssueTransitionEnabled().element.checked).toBe(true);

        const [radio1, radio2] = findIssueTransitionModeRadios().wrappers;
        expect(radio1.element.checked).toBe(false);
        expect(radio2.element.checked).toBe(true);

        const field = findIssueTransitionIdsField();
        expect(field.isVisible()).toBe(true);
        expect(field.element).toMatchObject({
          type: 'text',
          value: '1, 2, 3',
        });
      });
    });

    describe('initialJiraIssueTransitionAutomatic is true, initialJiraIssueTransitionId is set', () => {
      it('uses automatic transitions', () => {
        createComponent({
          initialTriggerCommit: true,
          initialJiraIssueTransitionAutomatic: true,
          initialJiraIssueTransitionId: '1, 2, 3',
        });

        expect(findIssueTransitionEnabled().element.checked).toBe(true);

        const [radio1, radio2] = findIssueTransitionModeRadios().wrappers;
        expect(radio1.element.checked).toBe(true);
        expect(radio2.element.checked).toBe(false);

        expect(findIssueTransitionIdsField().exists()).toBe(false);
      });
    });

    it('disables input fields if inheriting', () => {
      createComponent(
        {
          initialTriggerCommit: true,
          initialEnableComments: true,
          initialJiraIssueTransitionId: '1, 2, 3',
        },
        true,
      );

      wrapper.findAll('[type=text], [type=checkbox], [type=radio]').wrappers.forEach((input) => {
        expect(input.attributes('disabled')).toBeDefined();
      });
    });
  });
});
