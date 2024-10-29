import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import PipelineEditorDrawerSection from '~/ci/pipeline_editor/components/drawer/pipeline_editor_drawer_section.vue';

describe('Getting started section', () => {
  let wrapper;

  const defaultProps = {
    emoji: 'wave',
    title: 'Getting started',
  };

  const createComponent = () => {
    wrapper = shallowMountExtended(PipelineEditorDrawerSection, {
      propsData: {
        ...defaultProps,
      },
      slots: {
        default: '<span data-testid="default-slot">Content</span>',
      },
      stubs: ['gl-emoji'],
    });
  };

  const findDefaultSlot = () => wrapper.findByTestId('default-slot');
  const findEmoji = () => wrapper.findByTestId('title-emoji');

  beforeEach(() => {
    createComponent();
  });

  it('assigns the correct emoji', () => {
    expect(findEmoji().attributes('data-name')).toBe(defaultProps.emoji);
  });

  it('renders the title', () => {
    expect(wrapper.text()).toContain(defaultProps.title);
  });

  it('renders a default slot', () => {
    expect(findDefaultSlot().exists()).toBe(true);
  });
});
