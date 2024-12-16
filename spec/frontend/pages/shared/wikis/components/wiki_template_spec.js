import { mount, shallowMount } from '@vue/test-utils';
import { GlCollapsibleListbox } from '@gitlab/ui';
import WikiTemplate from '~/pages/shared/wikis/components/wiki_template.vue';

describe('WikiTemplate', () => {
  let wrapper;

  const templates = [
    { title: 'Template 1', path: '/path/to/template1', format: 'markdown' },
    { title: 'Template 2', path: '/path/to/template2', format: 'asciidoc' },
    { title: 'Template 3', path: '/path/to/template3', format: 'org' },
    { title: 'Template 4', path: '/path/to/template4', format: 'rdoc' },
    { title: 'Template 5', path: '/path/to/template5', format: 'markdown' },
    { title: 'Template 6', path: '/path/to/template6', format: 'asciidoc' },
    { title: 'Template 7', path: '/path/to/template7', format: 'org' },
    { title: 'Template 8', path: '/path/to/template8', format: 'rdoc' },
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
