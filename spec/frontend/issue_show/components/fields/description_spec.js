import { shallowMount } from '@vue/test-utils';
import DescriptionField from '~/issue_show/components/fields/description.vue';
import eventHub from '~/issue_show/event_hub';
import MarkdownField from '~/vue_shared/components/markdown/field.vue';

describe('Description field component', () => {
  let wrapper;

  const findTextarea = () => wrapper.find({ ref: 'textarea' });

  const mountComponent = (description = 'test') =>
    shallowMount(DescriptionField, {
      attachTo: document.body,
      propsData: {
        markdownPreviewPath: '/',
        markdownDocsPath: '/',
        formState: {
          description,
        },
      },
      stubs: {
        MarkdownField,
      },
    });

  beforeEach(() => {
    jest.spyOn(eventHub, '$emit');
  });

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  it('renders markdown field with description', () => {
    wrapper = mountComponent();

    expect(findTextarea().element.value).toBe('test');
  });

  it('renders markdown field with a markdown description', () => {
    const markdown = '**test**';

    wrapper = mountComponent(markdown);

    expect(findTextarea().element.value).toBe(markdown);
  });

  it('focuses field when mounted', () => {
    wrapper = mountComponent();

    expect(document.activeElement).toBe(findTextarea().element);
  });

  it('triggers update with meta+enter', () => {
    wrapper = mountComponent();

    findTextarea().trigger('keydown.enter', { metaKey: true });

    expect(eventHub.$emit).toHaveBeenCalledWith('update.issuable');
  });

  it('triggers update with ctrl+enter', () => {
    wrapper = mountComponent();

    findTextarea().trigger('keydown.enter', { ctrlKey: true });

    expect(eventHub.$emit).toHaveBeenCalledWith('update.issuable');
  });
});
