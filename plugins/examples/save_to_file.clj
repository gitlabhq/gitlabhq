#!/usr/bin/env clojure
(let [in (slurp *in*)]
  (spit "/tmp/clj-data.txt" in))
