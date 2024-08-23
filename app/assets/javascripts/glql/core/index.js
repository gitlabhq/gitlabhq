import Executor from './executor';
import Presenter from './presenter';

export const executeAndPresentQuery = async (query) => {
  const executor = await new Executor().init();
  const { data, config } = await executor.compile(query).execute();
  const { component } = new Presenter().init({
    data: (data.project || data.group).issues,
    config,
  });
  return component;
};
