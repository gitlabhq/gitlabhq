import { createLocalVue, shallowMount, mount } from '@vue/test-utils';
import Vuex from 'vuex';
import {
  TRANSITION_LOAD_START,
  TRANSITION_LOAD_ERROR,
  TRANSITION_LOAD_SUCCEED,
  TRANSITION_ACKNOWLEDGE_ERROR,
  STATE_IDLING,
  STATE_LOADING,
  STATE_ERRORED,
} from '~/diffs/constants';
import Renamed from '~/vue_shared/components/diff_viewer/viewers/renamed.vue';

const localVue = createLocalVue();
localVue.use(Vuex);

function createRenamedComponent({ props = {}, store = new Vuex.Store({}), deep = false }) {
  const mnt = deep ? mount : shallowMount;

  return mnt(Renamed, {
    propsData: { ...props },
    localVue,
    store,
  });
}

describe('Renamed Diff Viewer', () => {
  const DIFF_FILE_COMMIT_SHA = 'commitsha';
  const DIFF_FILE_SHORT_SHA = 'commitsh';
  const DIFF_FILE_VIEW_PATH = `blob/${DIFF_FILE_COMMIT_SHA}/filename.ext`;
  let diffFile;
  let wrapper;

  beforeEach(() => {
    diffFile = {
      content_sha: DIFF_FILE_COMMIT_SHA,
      view_path: DIFF_FILE_VIEW_PATH,
      alternate_viewer: {
        name: 'text',
      },
    };
  });

  afterEach(() => {
    if (wrapper) {
      wrapper.destroy();
      wrapper = null;
    }
  });

  describe('is', () => {
    beforeEach(() => {
      wrapper = createRenamedComponent({ props: { diffFile } });
    });

    it.each`
      state        | request      | result
      ${'idle'}    | ${'idle'}    | ${true}
      ${'idle'}    | ${'loading'} | ${false}
      ${'idle'}    | ${'errored'} | ${false}
      ${'loading'} | ${'loading'} | ${true}
      ${'loading'} | ${'idle'}    | ${false}
      ${'loading'} | ${'errored'} | ${false}
      ${'errored'} | ${'errored'} | ${true}
      ${'errored'} | ${'idle'}    | ${false}
      ${'errored'} | ${'loading'} | ${false}
    `(
      'returns the $result for "$request" when the state is "$state"',
      ({ request, result, state }) => {
        wrapper.vm.state = state;

        expect(wrapper.vm.is(request)).toEqual(result);
      },
    );
  });

  describe('transition', () => {
    beforeEach(() => {
      wrapper = createRenamedComponent({ props: { diffFile } });
    });

    it.each`
      state        | transition                      | result
      ${'idle'}    | ${TRANSITION_LOAD_START}        | ${STATE_LOADING}
      ${'idle'}    | ${TRANSITION_LOAD_ERROR}        | ${STATE_IDLING}
      ${'idle'}    | ${TRANSITION_LOAD_SUCCEED}      | ${STATE_IDLING}
      ${'idle'}    | ${TRANSITION_ACKNOWLEDGE_ERROR} | ${STATE_IDLING}
      ${'loading'} | ${TRANSITION_LOAD_START}        | ${STATE_LOADING}
      ${'loading'} | ${TRANSITION_LOAD_ERROR}        | ${STATE_ERRORED}
      ${'loading'} | ${TRANSITION_LOAD_SUCCEED}      | ${STATE_IDLING}
      ${'loading'} | ${TRANSITION_ACKNOWLEDGE_ERROR} | ${STATE_LOADING}
      ${'errored'} | ${TRANSITION_LOAD_START}        | ${STATE_LOADING}
      ${'errored'} | ${TRANSITION_LOAD_ERROR}        | ${STATE_ERRORED}
      ${'errored'} | ${TRANSITION_LOAD_SUCCEED}      | ${STATE_ERRORED}
      ${'errored'} | ${TRANSITION_ACKNOWLEDGE_ERROR} | ${STATE_IDLING}
    `(
      'correctly updates the state to "$result" when it starts as "$state" and the transition is "$transition"',
      ({ state, transition, result }) => {
        wrapper.vm.state = state;

        wrapper.vm.transition(transition);

        expect(wrapper.vm.state).toEqual(result);
      },
    );
  });

  describe('switchToFull', () => {
    let store;

    beforeEach(() => {
      store = new Vuex.Store({
        modules: {
          diffs: {
            namespaced: true,
            actions: { switchToFullDiffFromRenamedFile: () => {} },
          },
        },
      });

      jest.spyOn(store, 'dispatch');

      wrapper = createRenamedComponent({ props: { diffFile }, store });
    });

    afterEach(() => {
      store = null;
    });

    it('calls the switchToFullDiffFromRenamedFile action when the method is triggered', () => {
      store.dispatch.mockResolvedValue();

      wrapper.vm.switchToFull();

      return wrapper.vm.$nextTick().then(() => {
        expect(store.dispatch).toHaveBeenCalledWith('diffs/switchToFullDiffFromRenamedFile', {
          diffFile,
        });
      });
    });

    it.each`
      after            | resolvePromise         | resolution
      ${STATE_IDLING}  | ${'mockResolvedValue'} | ${'successful'}
      ${STATE_ERRORED} | ${'mockRejectedValue'} | ${'rejected'}
    `(
      'moves through the correct states during a $resolution request',
      ({ after, resolvePromise }) => {
        store.dispatch[resolvePromise]();

        expect(wrapper.vm.state).toEqual(STATE_IDLING);

        wrapper.vm.switchToFull();

        expect(wrapper.vm.state).toEqual(STATE_LOADING);

        return (
          wrapper.vm
            // This tick is needed for when the action (promise) finishes
            .$nextTick()
            // This tick waits for the state change in the promise .then/.catch to bubble into the component
            .then(() => wrapper.vm.$nextTick())
            .then(() => {
              expect(wrapper.vm.state).toEqual(after);
            })
        );
      },
    );
  });

  describe('clickLink', () => {
    let event;

    beforeEach(() => {
      event = {
        preventDefault: jest.fn(),
      };
    });

    it.each`
      alternateViewer | stops    | handled
      ${'text'}       | ${true}  | ${'should'}
      ${'nottext'}    | ${false} | ${'should not'}
    `(
      'given { alternate_viewer: { name: "$alternateViewer" } }, the click event $handled be handled in the component',
      ({ alternateViewer, stops }) => {
        wrapper = createRenamedComponent({
          props: {
            diffFile: {
              ...diffFile,
              alternate_viewer: { name: alternateViewer },
            },
          },
        });

        jest.spyOn(wrapper.vm, 'switchToFull').mockImplementation(() => {});

        wrapper.vm.clickLink(event);

        if (stops) {
          expect(event.preventDefault).toHaveBeenCalled();
          expect(wrapper.vm.switchToFull).toHaveBeenCalled();
        } else {
          expect(event.preventDefault).not.toHaveBeenCalled();
          expect(wrapper.vm.switchToFull).not.toHaveBeenCalled();
        }
      },
    );
  });

  describe('dismissError', () => {
    let transitionSpy;

    beforeEach(() => {
      wrapper = createRenamedComponent({ props: { diffFile } });
      transitionSpy = jest.spyOn(wrapper.vm, 'transition');
    });

    it(`transitions the component with "${TRANSITION_ACKNOWLEDGE_ERROR}"`, () => {
      wrapper.vm.dismissError();

      expect(transitionSpy).toHaveBeenCalledWith(TRANSITION_ACKNOWLEDGE_ERROR);
    });
  });

  describe('output', () => {
    it.each`
      altViewer    | nameDisplay
      ${'text'}    | ${'"text"'}
      ${'nottext'} | ${'"nottext"'}
      ${undefined} | ${undefined}
      ${null}      | ${null}
    `(
      'with { alternate_viewer: { name: $nameDisplay } }, renders the component',
      ({ altViewer }) => {
        const file = { ...diffFile };

        file.alternate_viewer.name = altViewer;
        wrapper = createRenamedComponent({ props: { diffFile: file } });

        expect(wrapper.find('[test-id="plaintext"]').text()).toEqual(
          'File renamed with no changes.',
        );
      },
    );

    it.each`
      altType      | linkText
      ${'text'}    | ${'Show file contents'}
      ${'nottext'} | ${`View file @ ${DIFF_FILE_SHORT_SHA}`}
    `(
      'includes a link to the full file for alternate viewer type "$altType"',
      ({ altType, linkText }) => {
        const file = { ...diffFile };

        file.alternate_viewer.name = altType;
        wrapper = createRenamedComponent({
          deep: true,
          props: { diffFile: file },
        });

        const link = wrapper.find('a');

        expect(link.text()).toEqual(linkText);
        expect(link.attributes('href')).toEqual(DIFF_FILE_VIEW_PATH);
      },
    );
  });
});
