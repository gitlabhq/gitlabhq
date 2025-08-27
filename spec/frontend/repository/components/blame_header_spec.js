import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import BlameHeader from '~/blob/components/blame_header.vue';
import BlamePreferences from '~/blame/preferences/blame_preferences.vue';

let wrapper;

const findBlamePreferences = () => wrapper.findComponent(BlamePreferences);

const createComponent = ({ hasRevsFile = false } = {}) => {
  wrapper = shallowMountExtended(BlameHeader, { provide: { hasRevsFile } });
};

describe('Blame header component', () => {
  it('renders a Blame preferences component with correct props', () => {
    createComponent({ hasRevsFile: true });

    expect(findBlamePreferences().props('hasRevsFile')).toBe(true);
  });
});
