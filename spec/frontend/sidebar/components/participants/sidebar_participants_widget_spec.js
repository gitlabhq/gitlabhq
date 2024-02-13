import { shallowMount } from '@vue/test-utils';
import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import SidebarParticipants from '~/sidebar/components/participants/sidebar_participants.vue';
import SidebarParticipantsWidget from '~/sidebar/components/participants/sidebar_participants_widget.vue';
import epicParticipantsQuery from '~/sidebar/queries/epic_participants.query.graphql';
import { epicParticipantsResponse } from '../../mock_data';

Vue.use(VueApollo);

describe('Sidebar Participants Widget', () => {
  /** @type {import('helpers/vue_test_utils_helper').ExtendedWrapper} */
  let wrapper;
  let fakeApollo;

  const findParticipants = () => wrapper.findComponent(SidebarParticipants);

  const createComponent = ({
    participantsQueryHandler = jest.fn().mockResolvedValue(epicParticipantsResponse()),
  } = {}) => {
    fakeApollo = createMockApollo([[epicParticipantsQuery, participantsQueryHandler]]);

    wrapper = shallowMount(SidebarParticipantsWidget, {
      apolloProvider: fakeApollo,
      propsData: {
        fullPath: 'group',
        iid: '1',
        issuableType: 'epic',
      },
    });
  };

  afterEach(() => {
    fakeApollo = null;
  });

  it('passes a `loading` prop as true to child component when query is loading', () => {
    createComponent();

    expect(findParticipants().props('loading')).toBe(true);
  });

  it('emits toggleSidebar event when participants child component emits toggleSidebar', async () => {
    createComponent();
    findParticipants().vm.$emit('toggleSidebar');

    await nextTick();
    expect(wrapper.emitted('toggleSidebar')).toEqual([[]]);
  });

  describe('when participants are loaded', () => {
    beforeEach(() => {
      createComponent({
        participantsQueryHandler: jest.fn().mockResolvedValue(epicParticipantsResponse()),
      });
      return waitForPromises();
    });

    it('passes a `loading` prop as false to editable item', () => {
      expect(findParticipants().props('loading')).toBe(false);
    });

    it('passes participants to child component', () => {
      expect(findParticipants().props('participants')).toEqual(
        epicParticipantsResponse().data.workspace.issuable.participants.nodes,
      );
    });
  });

  describe('when error occurs', () => {
    it('emits error event with correct parameters', async () => {
      const mockError = new Error('mayday');

      createComponent({
        participantsQueryHandler: jest.fn().mockRejectedValue(mockError),
      });

      await waitForPromises();

      const [
        [
          {
            message,
            error: { networkError },
          },
        ],
      ] = wrapper.emitted('fetch-error');
      expect(message).toBe(wrapper.vm.$options.i18n.fetchingError);
      expect(networkError).toEqual(mockError);
    });
  });
});
