import { GlButton, GlFormSelect, GlLoadingIcon, GlToggle } from '@gitlab/ui';
import { shallowMount, mount } from '@vue/test-utils';
import { nextTick } from 'vue';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import ServiceDeskSetting from '~/projects/settings_service_desk/components/service_desk_setting.vue';
import ClipboardButton from '~/vue_shared/components/clipboard_button.vue';

describe('ServiceDeskSetting', () => {
  let wrapper;

  const findButton = () => wrapper.find(GlButton);
  const findClipboardButton = () => wrapper.find(ClipboardButton);
  const findIncomingEmail = () => wrapper.findByTestId('incoming-email');
  const findIncomingEmailLabel = () => wrapper.findByTestId('incoming-email-describer');
  const findLoadingIcon = () => wrapper.find(GlLoadingIcon);
  const findTemplateDropdown = () => wrapper.find(GlFormSelect);
  const findToggle = () => wrapper.find(GlToggle);

  const createComponent = ({ props = {}, mountFunction = shallowMount } = {}) =>
    extendedWrapper(
      mountFunction(ServiceDeskSetting, {
        propsData: {
          isEnabled: true,
          ...props,
        },
      }),
    );

  afterEach(() => {
    if (wrapper) {
      wrapper.destroy();
    }
  });

  describe('when isEnabled=true', () => {
    describe('only isEnabled', () => {
      describe('as project admin', () => {
        beforeEach(() => {
          wrapper = createComponent();
        });

        it('should see activation checkbox', () => {
          expect(findToggle().props('label')).toBe(ServiceDeskSetting.i18n.toggleLabel);
        });

        it('should see main panel with the email info', () => {
          expect(findIncomingEmailLabel().exists()).toBe(true);
        });

        it('should see loading spinner and not the incoming email', () => {
          expect(findLoadingIcon().exists()).toBe(true);
          expect(findIncomingEmail().exists()).toBe(false);
        });
      });
    });

    describe('service desk toggle', () => {
      it('emits an event to turn on Service Desk when clicked', async () => {
        wrapper = createComponent();

        findToggle().vm.$emit('change', true);

        await nextTick();

        expect(wrapper.emitted('toggle')[0]).toEqual([true]);
      });
    });

    describe('with incomingEmail', () => {
      const incomingEmail = 'foo@bar.com';

      beforeEach(() => {
        wrapper = createComponent({
          props: { incomingEmail },
        });
      });

      it('should see email and not the loading spinner', () => {
        expect(findIncomingEmail().element.value).toEqual(incomingEmail);
        expect(findLoadingIcon().exists()).toBe(false);
      });

      it('renders a copy to clipboard button', () => {
        expect(findClipboardButton().exists()).toBe(true);
        expect(findClipboardButton().props()).toEqual(
          expect.objectContaining({
            title: 'Copy',
            text: incomingEmail,
          }),
        );
      });
    });

    describe('with customEmail', () => {
      describe('customEmail is different than incomingEmail', () => {
        const incomingEmail = 'foo@bar.com';
        const customEmail = 'custom@bar.com';

        beforeEach(() => {
          wrapper = createComponent({
            props: { incomingEmail, customEmail },
          });
        });

        it('should see custom email', () => {
          expect(findIncomingEmail().element.value).toEqual(customEmail);
        });
      });

      describe('customEmail is the same as incomingEmail', () => {
        const email = 'foo@bar.com';

        beforeEach(() => {
          wrapper = createComponent({
            props: { incomingEmail: email, customEmail: email },
          });
        });

        it('should see custom email', () => {
          expect(findIncomingEmail().element.value).toEqual(email);
        });
      });
    });

    describe('templates dropdown', () => {
      it('renders a dropdown to choose a template', () => {
        wrapper = createComponent();

        expect(findTemplateDropdown().exists()).toBe(true);
      });

      it('renders a dropdown with a default value of ""', () => {
        wrapper = createComponent({ mountFunction: mount });

        expect(findTemplateDropdown().element.value).toEqual('');
      });

      it('renders a dropdown with a value of "Bug" when it is the initial value', () => {
        const templates = ['Bug', 'Documentation', 'Security release'];

        wrapper = createComponent({
          props: { initialSelectedTemplate: 'Bug', templates },
          mountFunction: mount,
        });

        expect(findTemplateDropdown().element.value).toEqual('Bug');
      });

      it('renders a dropdown with no options when the project has no templates', () => {
        wrapper = createComponent({
          props: { templates: [] },
          mountFunction: mount,
        });

        // The dropdown by default has one empty option
        expect(findTemplateDropdown().element.children).toHaveLength(1);
      });

      it('renders a dropdown with options when the project has templates', () => {
        const templates = ['Bug', 'Documentation', 'Security release'];

        wrapper = createComponent({
          props: { templates },
          mountFunction: mount,
        });

        // An empty-named template is prepended so the user can select no template
        const expectedTemplates = [''].concat(templates);

        const dropdown = findTemplateDropdown();
        const dropdownList = Array.from(dropdown.element.children).map(
          (option) => option.innerText,
        );

        expect(dropdown.element.children).toHaveLength(expectedTemplates.length);
        expect(dropdownList.includes('Bug')).toEqual(true);
        expect(dropdownList.includes('Documentation')).toEqual(true);
        expect(dropdownList.includes('Security release')).toEqual(true);
      });
    });
  });

  describe('save button', () => {
    it('renders a save button to save a template', () => {
      wrapper = createComponent();

      expect(findButton().text()).toContain('Save changes');
    });

    it('emits a save event with the chosen template when the save button is clicked', async () => {
      wrapper = createComponent({
        props: {
          initialSelectedTemplate: 'Bug',
          initialOutgoingName: 'GitLab Support Bot',
          initialProjectKey: 'key',
        },
      });

      findButton().vm.$emit('click');

      await nextTick();

      const payload = {
        selectedTemplate: 'Bug',
        outgoingName: 'GitLab Support Bot',
        projectKey: 'key',
      };

      expect(wrapper.emitted('save')[0]).toEqual([payload]);
    });
  });

  describe('when isEnabled=false', () => {
    beforeEach(() => {
      wrapper = createComponent({
        props: { isEnabled: false },
      });
    });

    it('does not render email panel', () => {
      expect(findIncomingEmailLabel().exists()).toBe(false);
    });

    it('does not render template dropdown', () => {
      expect(findTemplateDropdown().exists()).toBe(false);
    });

    it('does not render template save button', () => {
      expect(findButton().exists()).toBe(false);
    });

    it('emits an event to turn on Service Desk when the toggle is clicked', async () => {
      findToggle().vm.$emit('change', false);

      await nextTick();

      expect(wrapper.emitted('toggle')[0]).toEqual([false]);
    });
  });
});
