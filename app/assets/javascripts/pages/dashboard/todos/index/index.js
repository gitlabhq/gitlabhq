import initTodosApp from '~/todos';
import Todos from './todos';

if (gon.features.todosVueApplication) {
  initTodosApp();
} else {
  new Todos(); // eslint-disable-line no-new
}
