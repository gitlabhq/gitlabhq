import { mount } from '@vue/test-utils';
import JiraTriggerFields from '~/integrations/edit/components/jira_trigger_fields.vue';
import { GlFormCheckbox } from '@gitlab/ui';

describe('JiraTriggerFields', () => {
  let wrapper;

  const defaultProps = {
    initialTriggerCommit: false,
    initialTriggerMergeRequest: false,
    initialEnableComments: false,
  };

  const createComponent = props => {
    wrapper = mount(JiraTriggerFields, {
      propsData: { ...defaultProps, ...props },
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

  describe('template', () => {
    describe('initialTriggerCommit and initialTriggerMergeRequest are false', () => {
      it('does not show comment settings', () => {
        createComponent();

        expect(findCommentSettings().isVisible()).toBe(false);
        expect(findCommentDetail().isVisible()).toBe(false);
      });
    });

    describe('initialTriggerCommit is true', () => {
      beforeEach(() => {
        createComponent({
          initialTriggerCommit: true,
        });
      });

      it('shows comment settings', () => {
        expect(findCommentSettings().isVisible()).toBe(true);
        expect(findCommentDetail().isVisible()).toBe(false);
      });

      // As per https://vuejs.org/v2/guide/forms.html#Checkbox-1,
      // browsers don't include unchecked boxes in form submissions.
      it('includes comment settings as false even if unchecked', () => {
        expect(
          findCommentSettings()
            .find('input[name="service[comment_on_event_enabled]"]')
            .exists(),
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
      it('shows comment settings', () => {
        createComponent({
          initialTriggerMergeRequest: true,
        });

        expect(findCommentSettings().isVisible()).toBe(true);
        expect(findCommentDetail().isVisible()).toBe(false);
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
  });
});
