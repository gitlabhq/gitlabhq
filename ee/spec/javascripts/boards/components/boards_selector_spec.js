import Vue from 'vue';
import BoardService from 'ee/boards/services/board_service';
import 'ee/boards/components/boards_selector';
import setTimeoutPromiseHelper from 'spec/helpers/set_timeout_promise_helper';
import mountComponent from 'spec/helpers/vue_mount_component_helper';

const throttleDuration = 1;

function waitForScroll() {
  return Vue.nextTick()
    .then(() => setTimeoutPromiseHelper(throttleDuration))
    .then(() => Vue.nextTick());
}

describe('BoardsSelector', () => {
  let vm;
  let scrollContainer;
  let scrollFade;
  let boardServiceResponse;
  const boards = new Array(20).fill()
    .map((board, id) => {
      const name = `board${id}`;

      return {
        id,
        name,
      };
    });

  beforeEach((done) => {
    loadFixtures('boards/show.html.raw');

    window.gl = window.gl || {};

    window.gl.boardService = new BoardService({
      boardsEndpoint: '',
      listsEndpoint: '',
      bulkUpdatePath: '',
      boardId: '',
    });

    boardServiceResponse = Promise.resolve({
      data: boards,
    });

    spyOn(BoardService.prototype, 'allBoards').and.returnValue(boardServiceResponse);

    vm = mountComponent(gl.issueBoards.BoardsSelector, {
      throttleDuration,
      currentBoard: {},
      milestonePath: '',
    }, document.querySelector('.js-boards-selector'));

    vm.$el.querySelector('.js-dropdown-toggle').click();

    boardServiceResponse
      .then(() => vm.$nextTick())
      .then(() => {
        scrollFade = vm.$el.querySelector('.js-scroll-fade');
        scrollContainer = scrollFade.querySelector('.js-dropdown-list');

        scrollContainer.style.maxHeight = '100px';
        scrollContainer.style.overflowY = 'scroll';
      })
      .then(done)
      .catch(done.fail);
  });

  afterEach(() => {
    vm.$destroy();
    window.gl.boardService = undefined;
  });

  it('shows the scroll fade if isScrolledUp', (done) => {
    scrollContainer.scrollTop = 0;

    waitForScroll()
      .then(() => {
        expect(scrollFade.classList.contains('fade-out')).toEqual(false);
      })
      .then(done)
      .catch(done.fail);
  });

  it('hides the scroll fade if not isScrolledUp', (done) => {
    scrollContainer.scrollTop = scrollContainer.scrollHeight;

    waitForScroll()
      .then(() => {
        expect(scrollFade.classList.contains('fade-out')).toEqual(true);
      })
      .then(done)
      .catch(done.fail);
  });
});
