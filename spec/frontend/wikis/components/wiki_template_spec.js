import { mount, shallowMount } from '@vue/test-utils';
import { nextTick } from 'vue';
import { GlCollapsibleListbox } from '@gitlab/ui';
import * as urlUtils from '~/lib/utils/url_utility';
import axios from '~/lib/utils/axios_utils';
import WikiTemplate from '~/wikis/components/wiki_template.vue';

describe('WikiTemplate', () => {
  let wrapper;

  const templates = [
    {
      title: 'Template 1',
      path: '/path/to/template1',
      format: 'markdown',
      slug: 'templates/template1',
    },
    {
      title: 'Template 2',
      path: '/path/to/template2',
      format: 'asciidoc',
      slug: 'templates/template2',
    },
    { title: 'Template 3', path: '/path/to/template3', format: 'org', slug: 'templates/template3' },
    {
      title: 'Template 4',
      path: '/path/to/template4',
      format: 'rdoc',
      slug: 'templates/template4',
    },
    {
      title: 'Template 5',
      path: '/path/to/template5',
      format: 'markdown',
      slug: 'templates/template5',
    },
    {
      title: 'Template 6',
      path: '/path/to/template6',
      format: 'asciidoc',
      slug: 'templates/template6',
    },
    { title: 'Template 7', path: '/path/to/template7', format: 'org', slug: 'templates/template7' },
    {
      title: 'Template 8',
      path: '/path/to/template8',
      format: 'rdoc',
      slug: 'templates/template8',
    },
  ];

  const defaultProps = {
    templates,
    format: 'markdown',
  };

  const createComponent = (props = {}, mountFn = shallowMount) => {
    wrapper = mountFn(WikiTemplate, {
      propsData: { ...defaultProps, ...props },
      provide: {
        templatesUrl: 'https://example.com',
      },
    });
  };

  const findListbox = () => wrapper.findComponent(GlCollapsibleListbox);

  const findManageTemplatesButton = () =>
    wrapper.findComponent('[data-testid="manage-templates-link"]');

  describe('autoSelectTemplate function', () => {
    beforeEach(() => {
      jest.clearAllMocks();
    });

    it('does not select template or emits input event if selected_template_slug is not present', async () => {
      jest.spyOn(urlUtils, 'getParameterByName').mockReturnValue(undefined);
      axios.get = jest.fn();

      createComponent();
      await nextTick();

      expect(wrapper.vm.selectedTemplatePath).toBeNull();
      expect(axios.get).not.toHaveBeenCalled();
      expect(wrapper.emitted('input')).toBe(undefined);
    });

    it('automatically selects the template and emits input event if valid selected_template_slug query param is passed', async () => {
      const selectedPath = templates[0].path;
      const selectedTemplateSlug = templates[0].slug;
      const expectedTemplateContent = 'template 1 content';

      jest.spyOn(urlUtils, 'getParameterByName').mockReturnValue(selectedTemplateSlug);
      axios.get = jest.fn().mockResolvedValue({ data: expectedTemplateContent });

      createComponent();
      await nextTick();
      await axios.get();

      expect(wrapper.vm.selectedTemplatePath).toBe(`${selectedPath}/raw`);
      expect(axios.get).toHaveBeenCalledWith(`${selectedPath}/raw`);
      expect(wrapper.emitted('input')[0]).toEqual([expectedTemplateContent]);
    });

    it('does not select template or emits input event if selected_template_slug does not match any template', async () => {
      jest.spyOn(urlUtils, 'getParameterByName').mockReturnValue('nonexistent/template');
      axios.get = jest.fn();

      createComponent();
      await nextTick();

      expect(wrapper.vm.selectedTemplatePath).toBeNull();
      expect(axios.get).not.toHaveBeenCalled();
      expect(wrapper.emitted('input')).toBe(undefined);
    });
  });

  it('renders a GlCollapsibleListbox with templates as items', () => {
    createComponent();

    expect(findListbox().exists()).toBe(true);
  });

  it.each`
    format        | expectedItems
    ${'markdown'} | ${['Template 1', 'Template 5']}
    ${'asciidoc'} | ${['Template 2', 'Template 6']}
    ${'org'}      | ${['Template 3', 'Template 7']}
    ${'rdoc'}     | ${['Template 4', 'Template 8']}
  `('renders $expectedItems items for format $format', ({ format, expectedItems }) => {
    createComponent({ format });

    expect(
      findListbox()
        .props('items')
        .map((item) => item.text),
    ).toEqual(expectedItems);
  });

  it('shows a link to the templates page in the dropdown footer', () => {
    createComponent();

    expect(findManageTemplatesButton().exists()).toBe(true);
    expect(findManageTemplatesButton().attributes('href')).toBe('https://example.com');
  });

  it('prevents xss by escaping template names before inserting in DOM', () => {
    createComponent(
      {
        templates: [
          {
            title: 'Malacious template <script>alert(1)</script>',
            path: '/path/to/template1',
            format: 'markdown',
          },
        ],
      },
      mount,
    );

    expect(wrapper.html()).toContain('Malacious template &lt;script&gt;alert(1)&lt;/script&gt;');
  });
});
