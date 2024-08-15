import Executor from './core/executor';
import Presenter from './core/presenter';

const renderGlqlNode = async (el) => {
  el.style.display = 'none';

  const query = el.textContent;
  const executor = await new Executor().init();
  const { data, config } = await executor.compile(query).execute();

  return new Presenter().init({ data: (data.project || data.group).issues, config }).mount(el);
};

const renderGlqlNodes = (els) => {
  return Promise.all([...els].map(renderGlqlNode));
};

export default renderGlqlNodes;
