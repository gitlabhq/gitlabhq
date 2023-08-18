import { shallowMount } from '@vue/test-utils';
import { nextTick } from 'vue';
import { GlFormInput } from '@gitlab/ui';
import { setHTMLFixture, resetHTMLFixture } from 'helpers/fixtures';
import FilepathForm from '~/blob/filepath_form/components/filepath_form.vue';
import TemplateSelector from '~/blob/filepath_form/components/template_selector.vue';
import { Templates as TemplatesMock } from './mock_data';

describe('Filepath Form component', () => {
  let wrapper;

  const findNavLinks = () => document.querySelector('.nav-links');
  const findNavLinkWrite = () => findNavLinks().querySelector('#edit');
  const findNavLinkPreview = () => findNavLinks().querySelector('#preview');

  const findInput = () => wrapper.findComponent(GlFormInput);
  const findTemplateSelector = () => wrapper.findComponent(TemplateSelector);

  const createComponent = (props = {}) => {
    wrapper = shallowMount(FilepathForm, {
      propsData: {
        templates: TemplatesMock,
        inputOptions: {},
        ...props,
      },
    });
  };

  beforeEach(() => {
    setHTMLFixture(`
      <div class="file-editor">
        <ul class="nav-links">
          <a class="nav-link" id="edit" href="#editor">Write</a>
          <a class="nav-link" id="preview" href="#preview">Preview</a>
        </ul>
      </div>
    `);
    createComponent();
  });

  afterEach(() => {
    resetHTMLFixture();
  });

  it('renders input with correct attributes', () => {
    createComponent({ inputOptions: { name: 'foo', value: 'bar' } });
    expect(findInput().attributes()).toMatchObject({
      name: 'foo',
      value: 'bar',
    });
  });

  describe('when write button is clicked', () => {
    it('renders template selector', async () => {
      findNavLinkWrite().click();
      await nextTick();

      expect(findTemplateSelector().exists()).toBe(true);
    });
  });

  describe('when preview button is clicked', () => {
    it('hides template selector', async () => {
      findNavLinkPreview().click();
      await nextTick();

      expect(findTemplateSelector().exists()).toBe(false);
    });
  });
});
