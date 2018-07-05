import '~/boards/components/board_sidebar';
import RemoveBtn from './sidebar/remove_issue';

const base = gl.issueBoards.BoardSidebar;

gl.issueBoards.BoardSidebar = base.extend({
  components: {
    RemoveBtn,
  },
});
