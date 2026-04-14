import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import BlameHeader from '~/blob/components/blame_header.vue';
import BlamePreferences from '~/blame/preferences/blame_preferences.vue';
import BlameLegend from '~/blame/blame_legend.vue';

let wrapper;

const findBlamePreferences = () => wrapper.findComponent(BlamePreferences);
const findBlameLegend = () => wrapper.findComponent(BlameLegend);

const createComponent = ({ hasRevsFile = false } = {}) => {
  wrapper = shallowMountExtended(BlameHeader, { provide: { hasRevsFile } });
};

describe('Blame header component', () => {
  it('renders a Blame preferences component with correct props', () => {
    createComponent({ hasRevsFile: true });

    expect(findBlamePreferences().props('hasRevsFile')).toBe(true);
  });

  it('hides the age indicator legend by default', () => {
    createComponent();

    expect(findBlameLegend().exists()).toBe(false);
  });

  it('shows the legend when preferences emits toggle-age-indicator with true', async () => {
    createComponent();

    await findBlamePreferences().vm.$emit('toggle-age-indicator', true);

    expect(findBlameLegend().exists()).toBe(true);
  });

  it('hides the legend when preferences emits toggle-age-indicator with false', async () => {
    createComponent();

    await findBlamePreferences().vm.$emit('toggle-age-indicator', true);
    expect(findBlameLegend().exists()).toBe(true);

    await findBlamePreferences().vm.$emit('toggle-age-indicator', false);
    expect(findBlameLegend().exists()).toBe(false);
  });
});
