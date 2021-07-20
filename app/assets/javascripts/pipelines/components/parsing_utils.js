import { memoize } from 'lodash';
import { createSankey } from './dag/drawing_utils';

/*
    The following functions are the main engine in transforming the data as
    received from the endpoint into the format the d3 graph expects.

    Input is of the form:
    [nodes]
      nodes: [{category, name, jobs, size}]
        category is the stage name
        name is a group name; in the case that the group has one job, it is
          also the job name
        size is the number of parallel jobs
        jobs: [{ name, needs}]
          job name is either the same as the group name or group x/y
          needs: [job-names]
          needs is an array of job-name strings

    Output is of the form:
    { nodes: [node], links: [link] }
      node: { name, category }, + unused info passed through
      link: { source, target, value }, with source & target being node names
        and value being a constant

    We create nodes in the GraphQL update function, and then here we create the node dictionary,
    then create links, and then dedupe the links, so that in the case where
    job 4 depends on job 1 and job 2, and job 2 depends on job 1, we show only a single link
    from job 1 to job 2 then another from job 2 to job 4.

    CREATE LINKS
    nodes.name -> target
    nodes.name.needs.each -> source (source is the name of the group, not the parallel job)
    10 -> value (constant)
  */

export const createNodeDict = (nodes) => {
  return nodes.reduce((acc, node) => {
    const newNode = {
      ...node,
      needs: node.jobs.map((job) => job.needs || []).flat(),
    };

    if (node.size > 1) {
      node.jobs.forEach((job) => {
        acc[job.name] = newNode;
      });
    }

    acc[node.name] = newNode;
    return acc;
  }, {});
};

export const makeLinksFromNodes = (nodes, nodeDict) => {
  const constantLinkValue = 10; // all links are the same weight
  return nodes
    .map(({ jobs, name: groupName }) =>
      jobs.map(({ needs = [] }) =>
        needs.reduce((acc, needed) => {
          // It's possible that we have an optional job, which
          // is being needed by another job. In that scenario,
          // the needed job doesn't exist, so we don't want to
          // create link for it.
          if (nodeDict[needed]?.name) {
            acc.push({
              source: nodeDict[needed].name,
              target: groupName,
              value: constantLinkValue,
            });
          }

          return acc;
        }, []),
      ),
    )
    .flat(2);
};

export const getAllAncestors = (nodes, nodeDict) => {
  const needs = nodes
    .map((node) => {
      return nodeDict[node]?.needs || '';
    })
    .flat()
    .filter(Boolean);

  if (needs.length) {
    return [...needs, ...getAllAncestors(needs, nodeDict)];
  }

  return [];
};

export const filterByAncestors = (links, nodeDict) =>
  links.filter(({ target, source }) => {
    /*

    for every link, check out it's target
    for every target, get the target node's needs
    then drop the current link source from that list

    call a function to get all ancestors, recursively
    is the current link's source in the list of all parents?
    then we drop this link

  */
    const targetNode = target;
    const targetNodeNeeds = nodeDict[targetNode].needs;
    const targetNodeNeedsMinusSource = targetNodeNeeds.filter((need) => need !== source);

    const allAncestors = getAllAncestors(targetNodeNeedsMinusSource, nodeDict);
    return !allAncestors.includes(source);
  });

/*
  A peformant alternative to lodash's isEqual. Because findIndex always finds
  the first instance of a match, if the found index is not the first, we know
  it is in fact a duplicate.
*/
const deduplicate = (item, itemIndex, arr) => {
  const foundIdx = arr.findIndex((test) => {
    return test.source === item.source && test.target === item.target;
  });

  return foundIdx === itemIndex;
};

export const parseData = (nodes) => {
  const nodeDict = createNodeDict(nodes);
  const allLinks = makeLinksFromNodes(nodes, nodeDict);
  const filteredLinks = filterByAncestors(allLinks, nodeDict);
  const links = filteredLinks.filter(deduplicate);

  return { nodes, links };
};

/*
  The number of nodes in the most populous generation drives the height of the graph.
*/

export const getMaxNodes = (nodes) => {
  const counts = nodes.reduce((acc, { layer }) => {
    if (!acc[layer]) {
      acc[layer] = 0;
    }

    acc[layer] += 1;

    return acc;
  }, []);

  return Math.max(...counts);
};

/*
  Because we cannot know if a node is part of a relationship until after we
  generate the links with createSankey, this function is used after the first call
  to find nodes that have no relations.
*/

export const removeOrphanNodes = (sankeyfiedNodes) => {
  return sankeyfiedNodes.filter((node) => node.sourceLinks.length || node.targetLinks.length);
};

/*
  This utility accepts unwrapped pipeline data in the format returned from
  our standard pipeline GraphQL query and returns a list of names by layer
  for the layer view. It can be combined with the stageLookup on the pipeline
  to generate columns by layer.
*/

export const listByLayers = ({ stages }) => {
  const arrayOfJobs = stages.flatMap(({ groups }) => groups);
  const parsedData = parseData(arrayOfJobs);
  const dataWithLayers = createSankey()(parsedData);

  return dataWithLayers.nodes.reduce((acc, { layer, name }) => {
    /* sort groups by layer */

    if (!acc[layer]) {
      acc[layer] = [];
    }

    acc[layer].push(name);

    return acc;
  }, []);
};

export const generateColumnsFromLayersListBare = ({ stages, stagesLookup }, pipelineLayers) => {
  return pipelineLayers.map((layers, idx) => {
    /*
      Look up the groups in each layer,
      then add each set of layer groups to a stage-like object.
    */

    const groups = layers.map((id) => {
      const { stageIdx, groupIdx } = stagesLookup[id];
      return stages[stageIdx]?.groups?.[groupIdx];
    });

    return {
      name: '',
      id: `layer-${idx}`,
      status: { action: null },
      groups: groups.filter(Boolean),
    };
  });
};

export const generateColumnsFromLayersListMemoized = memoize(generateColumnsFromLayersListBare);
