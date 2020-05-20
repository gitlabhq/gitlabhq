import { mount } from '@vue/test-utils';
import { trimText } from 'helpers/text_helper';
import ReleaseBlockMetadata from '~/releases/components/release_block_metadata.vue';
import { release as originalRelease } from '../mock_data';
import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';
import { cloneDeep } from 'lodash';

const mockFutureDate = new Date(9999, 0, 0).toISOString();
let mockIsFutureRelease = false;

jest.mock('~/vue_shared/mixins/timeago', () => ({
  methods: {
    timeFormatted() {
      return mockIsFutureRelease ? 'in 1 month' : '7 fortnights ago';
    },
    tooltipTitle() {
      return 'February 30, 2401';
    },
  },
}));

describe('Release block metadata', () => {
  let wrapper;
  let release;

  const factory = (releaseUpdates = {}) => {
    wrapper = mount(ReleaseBlockMetadata, {
      propsData: {
        release: {
          ...convertObjectPropsToCamelCase(release, { deep: true }),
          ...releaseUpdates,
        },
      },
    });
  };

  beforeEach(() => {
    release = cloneDeep(originalRelease);
  });

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
    mockIsFutureRelease = false;
  });

  const findReleaseDateInfo = () => wrapper.find('.js-release-date-info');

  describe('with all props provided', () => {
    beforeEach(() => factory());

    it('renders the release time info', () => {
      expect(trimText(findReleaseDateInfo().text())).toBe(`released 7 fortnights ago`);
    });
  });

  describe('with a future release date', () => {
    beforeEach(() => {
      mockIsFutureRelease = true;
      factory({ releasedAt: mockFutureDate });
    });

    it('renders the release date without the author name', () => {
      expect(trimText(findReleaseDateInfo().text())).toBe(`will be released in 1 month`);
    });
  });
});
