# GitLab utilities

We developed a number of utilities to ease development.

## [`MergeHash`](https://gitlab.com/gitlab-org/gitlab-ce/blob/master/lib/gitlab/utils/merge_hash.rb)

* Deep merges an array of hashes:

    ``` ruby
    Gitlab::Utils::MergeHash.merge(
      [{ hello: ["world"] },
       { hello: "Everyone" },
       { hello: { greetings: ['Bonjour', 'Hello', 'Hallo', 'Dzien dobry'] } },
        "Goodbye", "Hallo"]
    )
    ```

    Gives:

    ``` ruby
    [
      {
        hello:
          [
            "world",
            "Everyone",
            { greetings: ['Bonjour', 'Hello', 'Hallo', 'Dzien dobry'] }
          ]
      },
      "Goodbye"
    ]
    ```

* Extracts all keys and values from a hash into an array:

    ``` ruby
    Gitlab::Utils::MergeHash.crush(
      { hello: "world", this: { crushes: ["an entire", "hash"] } }
    )
    ```

    Gives:

    ``` ruby
    [:hello, "world", :this, :crushes, "an entire", "hash"]
    ```

## [`StrongMemoize`](https://gitlab.com/gitlab-org/gitlab-ce/blob/master/lib/gitlab/utils/strong_memoize.rb)

* Memoize the value even if it is `nil` or `false`.

    We often do `@value ||= compute`, however this doesn't work well if
    `compute` might eventually give `nil` and we don't want to compute again.
    Instead we could use `defined?` to check if the value is set or not.
    However it's tedious to write such pattern, and `StrongMemoize` would
    help us use such pattern.

    Instead of writing patterns like this:

    ``` ruby
    class Find
      def result
        return @result if defined?(@result)

        @result = search
      end
    end
    ```

    We could write it like:

    ``` ruby
    class Find
      include Gitlab::Utils::StrongMemoize

      def result
        strong_memoize(:result) do
          search
        end
      end
    end
    ```

* Clear memoization

    ``` ruby
    class Find
      include Gitlab::Utils::StrongMemoize
    end

    Find.new.clear_memoization(:result)
    ```
