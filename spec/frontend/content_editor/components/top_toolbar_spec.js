import { shallowMount } from '@vue/test-utils';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import TopToolbar from '~/content_editor/components/top_toolbar.vue';

describe('content_editor/components/top_toolbar', () => {
  let wrapper;
  let editor;

  const buildEditor = () => {
    editor = {};
  };

  const buildWrapper = () => {
    wrapper = extendedWrapper(
      shallowMount(TopToolbar, {
        propsData: {
          editor,
        },
      }),
    );
  };

  beforeEach(() => {
    buildEditor();
  });

  afterEach(() => {
    wrapper.destroy();
  });

  it.each`
    testId            | button
    ${'bold'}         | ${{ contentType: 'bold', iconName: 'bold', label: 'Bold' }}
    ${'italic'}       | ${{ contentType: 'italic', iconName: 'italic', label: 'Italic' }}
    ${'code'}         | ${{ contentType: 'code', iconName: 'code', label: 'Code' }}
    ${'blockquote'}   | ${{ contentType: 'blockquote', iconName: 'quote', label: 'Insert a quote' }}
    ${'bullet-list'}  | ${{ contentType: 'bullet_list', iconName: 'list-bulleted', label: 'Add a bullet list' }}
    ${'ordered-list'} | ${{ contentType: 'ordered_list', iconName: 'list-numbered', label: 'Add a numbered list' }}
  `('renders $testId button', ({ testId, buttonProps }) => {
    buildWrapper();
    expect(wrapper.findByTestId(testId).props()).toMatchObject({
      ...buttonProps,
      editor,
    });
  });
});
