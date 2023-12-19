import {
  REPO_GRAPH_SCROLL_BOTTOM,
  REPO_GRAPH_SCROLL_DOWN,
  REPO_GRAPH_SCROLL_LEFT,
  REPO_GRAPH_SCROLL_RIGHT,
  REPO_GRAPH_SCROLL_TOP,
  REPO_GRAPH_SCROLL_UP,
} from './keybindings';
import ShortcutsNavigation from './shortcuts_navigation';

export default class ShortcutsNetwork {
  constructor(shortcuts, graph) {
    shortcuts.addAll([
      [REPO_GRAPH_SCROLL_LEFT, graph.scrollLeft],
      [REPO_GRAPH_SCROLL_RIGHT, graph.scrollRight],
      [REPO_GRAPH_SCROLL_UP, graph.scrollUp],
      [REPO_GRAPH_SCROLL_DOWN, graph.scrollDown],
      [REPO_GRAPH_SCROLL_TOP, graph.scrollTop],
      [REPO_GRAPH_SCROLL_BOTTOM, graph.scrollBottom],
    ]);
  }

  static dependencies = [ShortcutsNavigation];
}
