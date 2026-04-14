import { GlButton, GlCard, GlLoadingIcon } from '@gitlab/ui';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { createAlert } from '~/alert';
import PersonalAccessTokenStatistics from '~/personal_access_tokens/components/personal_access_token_statistics.vue';
import getUserPersonalAccessTokenStatistics from '~/personal_access_tokens/graphql/get_user_personal_access_token_statistics.query.graphql';
import { mockStatisticsResponse } from '../mock_data';

jest.mock('~/alert');
jest.mock('~/vue_shared/access_tokens/utils', () => ({
  fifteenDaysFromNow: jest.fn(() => '2025-01-21'),
}));

Vue.use(VueApollo);

describe('PersonalAccessTokenStatistics', () => {
  let wrapper;
  let mockApollo;

  const mockQueryHandler = jest.fn().mockResolvedValue(mockStatisticsResponse);

  const createComponent = ({ queryHandler = mockQueryHandler } = {}) => {
    mockApollo = createMockApollo([[getUserPersonalAccessTokenStatistics, queryHandler]]);

    window.gon = { current_user_id: 123 };

    wrapper = shallowMountExtended(PersonalAccessTokenStatistics, {
      apolloProvider: mockApollo,
      stubs: {
        GlCard,
      },
    });
  };

  const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);
  const findCards = () => wrapper.findAllComponents(GlCard);
  const findFilterButtons = () => wrapper.findAllComponents(GlButton);

  beforeEach(() => {
    createComponent();
  });

  describe('loading state', () => {
    it('shows loading icon while fetching statistics', () => {
      expect(findLoadingIcon().exists()).toBe(true);
    });

    it('hides loading icon after data is loaded', async () => {
      await waitForPromises();

      expect(findLoadingIcon().exists()).toBe(false);
    });
  });

  describe('GraphQL query', () => {
    it('calls the query with correct variables', async () => {
      await waitForPromises();

      expect(mockQueryHandler).toHaveBeenCalledWith({
        id: 'gid://gitlab/User/123',
        expiresBefore: '2025-01-21',
      });
    });

    it('handles query errors', async () => {
      const errorHandler = jest.fn().mockRejectedValue(new Error('GraphQL error'));
      createComponent({ queryHandler: errorHandler });

      await waitForPromises();

      expect(createAlert).toHaveBeenCalledWith({
        message: 'An error occurred while fetching token statistics.',
        variant: 'danger',
      });
    });
  });

  describe('statistics cards', () => {
    beforeEach(async () => {
      await waitForPromises();
    });

    it('renders four statistic cards', () => {
      expect(findCards()).toHaveLength(4);
    });

    it('displays correct statistics data', () => {
      const expected = [
        { title: 'Active tokens', value: 5 },
        { title: 'Tokens expiring in 2 weeks', value: 2 },
        { title: 'Revoked tokens', value: 3 },
        { title: 'Expired tokens', value: 1 },
      ];

      findCards().wrappers.forEach((card, i) => {
        expect(card.find('[data-testid="stat-title"]').text()).toBe(expected[i].title);
        expect(card.find('[data-testid="stat-value"]').text()).toBe(String(expected[i].value));
      });
    });

    it('renders filter buttons for each statistic', () => {
      expect(findFilterButtons()).toHaveLength(4);

      findFilterButtons().wrappers.forEach((button) => {
        expect(button.props('variant')).toBe('link');
        expect(button.text()).toBe('Filter list');
      });
    });

    it('sets correct tooltip titles for filter buttons', () => {
      expect(findFilterButtons().at(0).attributes('title')).toBe('Filter for active tokens');
      expect(findFilterButtons().at(1).attributes('title')).toBe(
        'Filter for tokens expiring in 2 weeks',
      );
      expect(findFilterButtons().at(2).attributes('title')).toBe('Filter for revoked tokens');
      expect(findFilterButtons().at(3).attributes('title')).toBe('Filter for expired tokens');
    });
  });

  describe('statistics filtering', () => {
    beforeEach(async () => {
      await waitForPromises();
    });

    it('emits filter event when active tokens filter button is clicked', async () => {
      await findFilterButtons().at(0).vm.$emit('click');

      expect(wrapper.emitted('filter')).toEqual([
        [
          [
            {
              type: 'state',
              value: {
                data: 'ACTIVE',
                operator: '=',
              },
            },
          ],
        ],
      ]);
    });

    it('emits filter event when expiring soon filter button is clicked', async () => {
      await findFilterButtons().at(1).vm.$emit('click');

      expect(wrapper.emitted('filter')).toEqual([
        [
          [
            {
              type: 'state',
              value: {
                data: 'ACTIVE',
                operator: '=',
              },
            },
            {
              type: 'expires',
              value: {
                data: '2025-01-21',
                operator: '<',
              },
            },
          ],
        ],
      ]);
    });

    it('emits filter event when revoked tokens filter button is clicked', async () => {
      await findFilterButtons().at(2).vm.$emit('click');

      expect(wrapper.emitted('filter')).toEqual([
        [
          [
            {
              type: 'revoked',
              value: {
                data: true,
                operator: '=',
              },
            },
          ],
        ],
      ]);
    });

    it('emits filter event when expired tokens filter button is clicked', async () => {
      await findFilterButtons().at(3).vm.$emit('click');

      expect(wrapper.emitted('filter')).toEqual([
        [
          [
            {
              type: 'revoked',
              value: {
                data: false,
                operator: '=',
              },
            },
            {
              type: 'state',
              value: {
                data: 'INACTIVE',
                operator: '=',
              },
            },
          ],
        ],
      ]);
    });
  });
});
