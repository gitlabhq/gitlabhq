import { GlCollapsibleListbox } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { nextTick } from 'vue';
import TemplateSelector from '~/blob/filepath_form/components/template_selector.vue';
import { Templates as TemplatesMock } from './mock_data';

describe('Template Selector component', () => {
  let wrapper;

  const findListbox = () => wrapper.findComponent(GlCollapsibleListbox);
  const findDisplayedTemplates = () =>
    findListbox()
      .props('items')
      .reduce((acc, item) => [...acc, ...item.options], [])
      .map((template) => template.value);

  const getTemplateKeysFromMock = (key) =>
    Object.values(TemplatesMock[key])
      .reduce((acc, items) => [...acc, ...items], [])
      .map((template) => template.key);

  const createComponent = (props = {}) => {
    wrapper = shallowMount(TemplateSelector, {
      propsData: {
        filename: '',
        templates: TemplatesMock,
        ...props,
      },
    });
  };

  describe('when filename input is empty', () => {
    beforeEach(() => {
      createComponent();
    });

    it('does not render listbox', () => {
      expect(findListbox().exists()).toBe(false);
    });
  });

  describe.each`
    filename            | key
    ${'LICENSE'}        | ${'licenses'}
    ${'Dockerfile'}     | ${'dockerfile_names'}
    ${'.gitignore'}     | ${'gitignore_names'}
    ${'.gitlab-ci.yml'} | ${'gitlab_ci_ymls'}
  `('when filename is $filename', ({ filename, key }) => {
    beforeEach(() => {
      createComponent({ filename });
    });

    it('renders listbox with correct props', () => {
      expect(findListbox().exists()).toBe(true);
      expect(findListbox().props('toggleText')).toBe('Apply a template');
      expect(findListbox().props('searchPlaceholder')).toBe('Filter');
      expect(findDisplayedTemplates()).toEqual(getTemplateKeysFromMock(key));
    });
  });

  describe('has filename that matches template pattern', () => {
    const filename = 'LICENSE';
    const templates = TemplatesMock.licenses.Other;

    describe('has initial template prop', () => {
      const initialTemplate = TemplatesMock.licenses.Other[0];

      beforeEach(() => {
        createComponent({ filename, initialTemplate: initialTemplate.key });
      });

      it('renders listbox toggle button with selected template name', () => {
        expect(findListbox().props('toggleText')).toBe(initialTemplate.name);
      });

      it('selected template is checked', () => {
        expect(findListbox().props('selected')).toBe(initialTemplate.key);
      });
    });

    describe('when template is selected', () => {
      beforeEach(() => {
        createComponent({ filename });
        findListbox().vm.$emit('select', templates[0].key);
      });

      it('emit `selected` event with selected template', () => {
        const licenseSelectorType = {
          key: 'licenses',
          name: 'LICENSE',
          pattern: /^(.+\/)?(licen[sc]e|copying)($|\.)/i,
          type: 'licenses',
        };

        const { template, type } = wrapper.emitted('selected')[0][0];
        expect(template).toStrictEqual(templates[0]);
        expect(type).toMatchObject(licenseSelectorType);
      });

      it('set loading state to true', () => {
        expect(findListbox().props('loading')).toBe(true);
      });

      describe('when stopLoading callback from `selected` event is called', () => {
        it('set loading state to false', async () => {
          const { stopLoading } = wrapper.emitted('selected')[0][0];

          stopLoading();
          await nextTick();

          expect(findListbox().props('loading')).toBe(false);
        });
      });
    });

    describe('when searching for filter', () => {
      const searchTerm = 'GNU';

      beforeEach(() => {
        createComponent({ filename: 'LICENSE' });
        findListbox().vm.$emit('search', searchTerm);
      });

      it('shows matching templates', () => {
        const displayedTemplates = findDisplayedTemplates();
        const matchingTemplate = templates.find((template) =>
          template.name.toLowerCase().includes(searchTerm.toLowerCase()),
        );
        expect(displayedTemplates).toContain(matchingTemplate?.key);
      });

      it('hides non-matching templates', () => {
        const displayedTemplates = findDisplayedTemplates();
        const nonMatchingTemplate = templates.find(
          (template) => !template.name.includes(searchTerm),
        );
        expect(displayedTemplates).not.toContain(nonMatchingTemplate?.key);
      });
    });
  });
});
