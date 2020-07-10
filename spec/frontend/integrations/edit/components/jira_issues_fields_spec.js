import { mount } from '@vue/test-utils';
import JiraIssuesFields from '~/integrations/edit/components/jira_issues_fields.vue';
import { GlFormCheckbox, GlFormInput } from '@gitlab/ui';

describe('JiraIssuesFields', () => {
  let wrapper;

  const defaultProps = {
    editProjectPath: '/edit',
  };

  const createComponent = props => {
    wrapper = mount(JiraIssuesFields, {
      propsData: { ...defaultProps, ...props },
    });
  };

  afterEach(() => {
    if (wrapper) {
      wrapper.destroy();
      wrapper = null;
    }
  });

  const findEnableCheckbox = () => wrapper.find(GlFormCheckbox);
  const findProjectKey = () => wrapper.find(GlFormInput);

  describe('template', () => {
    describe('Enable Jira issues checkbox', () => {
      beforeEach(() => {
        createComponent({ initialProjectKey: '' });
      });

      // As per https://vuejs.org/v2/guide/forms.html#Checkbox-1,
      // browsers don't include unchecked boxes in form submissions.
      it('includes issues_enabled as false even if unchecked', () => {
        expect(wrapper.contains('input[name="service[issues_enabled]"]')).toBe(true);
      });

      it('disables project_key input', () => {
        expect(findProjectKey().attributes('disabled')).toBe('disabled');
      });

      describe('on enable issues', () => {
        it('enables project_key input', () => {
          findEnableCheckbox().vm.$emit('input', true);

          return wrapper.vm.$nextTick().then(() => {
            expect(findProjectKey().attributes('disabled')).toBeUndefined();
          });
        });
      });
    });

    it('contains link to editProjectPath', () => {
      createComponent();

      expect(wrapper.contains(`a[href="${defaultProps.editProjectPath}"]`)).toBe(true);
    });
  });
});
