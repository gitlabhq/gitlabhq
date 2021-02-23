import { GlFormCheckbox } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import JiraTriggerFields from '~/integrations/edit/components/jira_trigger_fields.vue';

describe('JiraTriggerFields', () => {
  let wrapper;

  const defaultProps = {
    initialTriggerCommit: false,
    initialTriggerMergeRequest: false,
    initialEnableComments: false,
  };

  const createComponent = (props, isInheriting = false) => {
    wrapper = mount(JiraTriggerFields, {
      propsData: { ...defaultProps, ...props },
      computed: {
        isInheriting: () => isInheriting,
      },
    });
  };

  afterEach(() => {
    if (wrapper) {
      wrapper.destroy();
      wrapper = null;
    }
  });

  const findCommentSettings = () => wrapper.find('[data-testid="comment-settings"]');
  const findCommentDetail = () => wrapper.find('[data-testid="comment-detail"]');
  const findCommentSettingsCheckbox = () => findCommentSettings().find(GlFormCheckbox);
  const findIssueTransitionSettings = () =>
    wrapper.find('[data-testid="issue-transition-settings"]');
  const findIssueTransitionModeRadios = () =>
    findIssueTransitionSettings().findAll('input[type="radio"]');
  const findIssueTransitionIdsField = () =>
    wrapper.find('input[type="text"][name="service[jira_issue_transition_id]"]');

  describe('template', () => {
    describe('initialTriggerCommit and initialTriggerMergeRequest are false', () => {
      it('does not show trigger settings', () => {
        createComponent();

        expect(findCommentSettings().isVisible()).toBe(false);
        expect(findCommentDetail().isVisible()).toBe(false);
        expect(findIssueTransitionSettings().isVisible()).toBe(false);
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
        expect(findIssueTransitionSettings().isVisible()).toBe(true);
      });

      // As per https://vuejs.org/v2/guide/forms.html#Checkbox-1,
      // browsers don't include unchecked boxes in form submissions.
      it('includes comment settings as false even if unchecked', () => {
        expect(
          findCommentSettings().find('input[name="service[comment_on_event_enabled]"]').exists(),
        ).toBe(true);
      });

      describe('on enable comments', () => {
        it('shows comment detail', () => {
          findCommentSettingsCheckbox().vm.$emit('input', true);

          return wrapper.vm.$nextTick().then(() => {
            expect(findCommentDetail().isVisible()).toBe(true);
          });
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
        expect(findIssueTransitionSettings().isVisible()).toBe(true);
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

    describe('initialJiraIssueTransitionId is not set', () => {
      it('uses automatic transitions', () => {
        createComponent({
          initialTriggerCommit: true,
        });

        const [radio1, radio2] = findIssueTransitionModeRadios().wrappers;
        expect(radio1.element.checked).toBe(true);
        expect(radio2.element.checked).toBe(false);

        expect(findIssueTransitionIdsField().exists()).toBe(false);
      });
    });

    describe('initialJiraIssueTransitionId is set', () => {
      it('uses custom transitions', () => {
        createComponent({
          initialJiraIssueTransitionId: '1, 2, 3',
          initialTriggerCommit: true,
        });

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

    it('disables input fields if inheriting', () => {
      createComponent(
        {
          initialTriggerCommit: true,
          initialEnableComments: true,
        },
        true,
      );

      wrapper.findAll('[type=text], [type=checkbox], [type=radio]').wrappers.forEach((input) => {
        expect(input.attributes('disabled')).toBe('disabled');
      });
    });
  });
});
